ifndef APP_NAME
	APP_NAME = blog
endif

ifndef WORDPRESS_VERSION
	WORDPRESS_VERSION = 4.9.6
endif

ifndef BUILDPACK_VERSION
	BUILDPACK_VERSION = v149
endif

ifndef DOKKU_USER
	DOKKU_USER = dokku
endif

ifdef UNATTENDED_CREATION
	DOKKU_CMD = ssh $(DOKKU_USER)@$(SERVER_NAME)
else
	DOKKU_CMD = dokku
endif

CURL_INSTALLED := $(shell command -v curl 2> /dev/null)
WGET_INSTALLED := $(shell command -v wget 2> /dev/null)

.PHONY: all
all: help ## outputs the help message

.PHONY: help
help: ## this help.
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-36s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## builds a wordpress blog installation and outputs deploy instructions
ifndef APP_NAME
	$(error "Missing APP_NAME environment variable, this should be the name of your blog app")
endif
ifndef SERVER_NAME
	$(error "Missing SERVER_NAME environment variable, this should be something like 'dokku.me'")
endif
ifndef CURL_INSTALLED
ifndef WGET_INSTALLED
	$(error "Neither curl nor wget are installed, and at least one is necessary for retrieving salts")
endif
endif
	# creating the wordpress repo
	@test -d $(APP_NAME) || (git clone --depth=1 --quiet --branch=$(WORDPRESS_VERSION) --single-branch https://github.com/WordPress/WordPress.git $(APP_NAME) && cd $(APP_NAME) && git checkout -qb master)
	# adding wp-config.php from gist
	@test -f $(APP_NAME)/wp-config.php || (cp config/wp-config.php $(APP_NAME)/wp-config.php && cd $(APP_NAME) && git add wp-config.php && git commit -qm "Adding environment-variable based wp-config.php")
	# adding .env file to configure buildpack
	@test -f $(APP_NAME)/.buildpacks   || (echo "https://github.com/heroku/heroku-buildpack-php.git#$(BUILDPACK_VERSION)" > $(APP_NAME)/.buildpacks && cd $(APP_NAME) && git add .buildpacks && git commit -qm "Forcing php buildpack usage")
	# ensuring our composer.json loads with php 5.6 and loads the mysql extension
	@test -f $(APP_NAME)/composer.json || (cp config/composer.json $(APP_NAME)/composer.json && cp config/composer.lock $(APP_NAME)/composer.lock && cd $(APP_NAME) && git add composer.json composer.lock && git commit -qm "Use PHP 5.6 and the mysql extension")
	# setting the correct dokku remote for your app and server combination
	@cd $(APP_NAME) && (git remote rm dokku 2> /dev/null || true) && git remote add dokku "dokku@$(SERVER_NAME):$(APP_NAME)"
	# retrieving potential salts and writing them to /tmp/wp-salts
ifdef CURL_INSTALLED
	@curl -so /tmp/wp-salts https://api.wordpress.org/secret-key/1.1/salt/
else
ifdef WGET_INSTALLED
	@wget -qO /tmp/wp-salts https://api.wordpress.org/secret-key/1.1/salt/
endif
endif
	@sed -i.bak -e 's/ //g' -e "s/);//g" -e "s/define('/$(DOKKU_CMD) config:set $(APP_NAME) /g" -e "s/SALT',/SALT=/g" -e "s/KEY',[ ]*/KEY=/g" /tmp/wp-salts && rm /tmp/wp-salts.bak

ifndef UNATTENDED_CREATION
	# run the following commands on the server to setup the app:
	@echo ""
	@echo "dokku apps:create $(APP_NAME)"
	@echo ""
	# setup plugins persistent storage
	@echo ""
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "dokku storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-plugins:/app/wp-content/plugins"
	@echo ""
	# setup upload persistent storage
	@echo ""
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "dokku storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-uploads:/app/wp-content/uploads"
	@echo ""
	# setup languages persistent storage
	@echo ""
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-languages"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-languages"
	@echo "dokku storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-languages:/app/wp-content/languages"
	@echo ""
	# setup your mysql database and link it to your app
	# if you're using MariaDB, replace mysql with mariadb
	@echo ""
	@echo "export MYSQL_IMAGE_VERSION=\"5.6\""
	@echo "dokku mysql:create $(APP_NAME)-database"
	@echo "dokku mysql:link $(APP_NAME)-database $(APP_NAME)"
	@echo ""
	# you will also need to set the proper environment variables for keys and salts
	# the following were generated using the wordpress salt api: https://api.wordpress.org/secret-key/1.1/salt/
	# and use the following commands to set them up:
	@echo ""
	@cat /tmp/wp-salts
	@echo ""
	# now, on your local machine, change directory to your new wordpress app, and push it up
	@echo ""
	@echo "cd $(APP_NAME)"
	@echo "git push dokku master"
else
	@chmod +x /tmp/wp-salts
	$(DOKKU_CMD) apps:create $(APP_NAME)
	$(DOKKU_CMD) storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-plugins:/app/wp-content/plugins
	$(DOKKU_CMD) storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-uploads:/app/wp-content/uploads
	$(DOKKU_CMD) storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-languages:/app/wp-content/languages
	$(DOKKU_CMD) mysql:create $(APP_NAME)-database
	$(DOKKU_CMD) mysql:link $(APP_NAME)-database $(APP_NAME)
	@/tmp/wp-salts
	@echo ""
	# run the following commands on the server to ensure data is stored properly on disk
	@echo ""
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-languages"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-languages"
	@echo ""
	# now, on your local machine, change directory to your new wordpress app, and push it up
	@echo ""
	@echo "cd $(APP_NAME)"
	@echo "git push dokku master"
endif

.PHONY: destroy
destroy: ## destroys an existing wordpress blog installation and outputs undeploy instructions
ifndef APP_NAME
	$(error "Missing APP_NAME environment variable, this should be the name of your blog app")
endif
ifndef SERVER_NAME
	$(error "Missing SERVER_NAME environment variable, this should be something like 'dokku.me'")
endif
ifndef UNATTENDED_CREATION
	# destroy the mysql database
	# if you're using MariaDB, replace mysql with mariadb
	@echo ""
	@echo "dokku mysql:unlink $(APP_NAME)-database $(APP_NAME)"
	@echo "dokku mysql:destroy $(APP_NAME)-database"
	@echo ""
	# destroy the app
	@echo ""
	@echo "dokku -- --force apps:destroy $(APP_NAME)"
	@echo ""
	# run the following commands on the server to remove storage directories on disk
	@echo ""
	@echo "rm -rf /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "rm -rf /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "rm -rf /var/lib/dokku/data/storage/$(APP_NAME)-languages"
	@echo ""
	# now, on your local machine, cd into your app's parent directory and remove the app
	@echo ""
	@echo "rm -rf $(APP_NAME)"
else
	# destroy the mysql database
	# if you're using MariaDB, replace mysql with mariadb
	$(DOKKU_CMD) mysql:unlink $(APP_NAME)-database $(APP_NAME)
	$(DOKKU_CMD) mysql:destroy $(APP_NAME)-database
	# destroy the app
	$(DOKKU_CMD) -- --force apps:destroy $(APP_NAME)
	# run the following commands on the server to remove storage directories on disk
	@echo ""
	@echo "rm -rf /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "rm -rf /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "rm -rf /var/lib/dokku/data/storage/$(APP_NAME)-languages"
	@echo ""
	# now, on your local machine, cd into your app's parent directory and remove the app
	@echo ""
	@echo "rm -rf $(APP_NAME)"
endif
