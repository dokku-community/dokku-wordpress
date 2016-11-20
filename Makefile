ifndef APP_NAME
	APP_NAME = blog
endif

ifndef WORDPRESS_VERSION
	WORDPRESS_VERSION = 3.7.16
endif

ifndef BUILDPACK_VERSION
	BUILDPACK_VERSION = v114
endif

ifndef MYSQL_IMAGE_VERSION
	MYSQL_IMAGE_VERSION = 5.6.34
endif

COMPOSER := $(shell command -v composer 2> /dev/null)


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
ifndef COMPOSER
    $(error "composer binary is not available, please install composer into your system path")
endif
	# creating the wordpress repo
	@test -d $(APP_NAME) || (git clone --quiet https://github.com/WordPress/WordPress.git $(APP_NAME) && cd $(APP_NAME) && git checkout -q tags/$(WORDPRESS_VERSION) && git branch -qD master && git checkout -qb master)
	# adding wp-config.php from gist
	@test -f $(APP_NAME)/wp-config.php || (wget -q -O $(APP_NAME)/wp-config.php https://gist.githubusercontent.com/josegonzalez/ac94bf95b9085b606c72078f7f4a5591/raw/66635135545238de1053e3b47107dec6dedaa188/wp-config.php && cd $(APP_NAME) && git add wp-config.php && git commit -qm "Adding environment-variable based wp-config.php")
	# adding .env file to configure buildpack
	@test -f $(APP_NAME)/.buildpacks   || (echo "https://github.com/heroku/heroku-buildpack-php.git#$(BUILDPACK_VERSION)" > $(APP_NAME)/.buildpacks && cd $(APP_NAME) && git add .buildpacks && git commit -qm "Forcing php buildpack usage")
	# ensuring our composer.json loads with php 5.6 and loads the mysql extension
	# run `composer install` if dokku complains about missing a composer.lock
	@test -f $(APP_NAME)/composer.json || (echo '{"require": {"php": ">=5.6", "ext-mysql": "*"}}' > $(APP_NAME)/composer.json && cd $(APP_NAME) && composer update && git add composer.json composer.lock && git commit -qm "Use PHP 5.6 and the mysql extension")
	# setting the correct dokku remote for your app and server combination
	@cd $(APP_NAME) && (git remote rm dokku 2> /dev/null || true) && git remote add dokku "dokku@$(SERVER_NAME):$(APP_NAME)"
	# retrieving potential salts and writing them to /tmp/wp-salts
	@wget -qO /tmp/wp-salts https://api.wordpress.org/secret-key/1.1/salt/
	# run the following commands on the server to setup the app:
	@echo ""
	@echo "dokku apps:create $(APP_NAME)"
	@echo ""
	# setup plugins persistent storage
	@echo ""
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-plugins"
	@echo "dokku storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-plugins:/apps/wp-content/plugins"
	@echo ""
	# setup upload persistent storage
	@echo ""
	@echo "mkdir -p /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "chown 32767:32767 /var/lib/dokku/data/storage/$(APP_NAME)-uploads"
	@echo "dokku storage:mount $(APP_NAME) /var/lib/dokku/data/storage/$(APP_NAME)-uploads:/apps/wp-content/uploads"
	@echo ""
	# setup your mysql database and link it to your app
	@echo ""
	@echo "export MYSQL_IMAGE_VERSION=$(MYSQL_IMAGE_VERSION)"
	@echo "dokku mysql:create $(APP_NAME)-database"
	@echo "dokku mysql:link $(APP_NAME)-database $(APP_NAME)"
	@echo ""
	# you will also need to set the proper environment variables for keys and salts
	# the following were generated using the wordpress salt api: https://api.wordpress.org/secret-key/1.1/salt/
	# and use the following commands to set them up:
	@echo ""
	@sed -i.bak -e "s/);//g" -e "s/define('/dokku config:set $(APP_NAME) /g" -e "s/SALT',[ ]*/SALT=/g" -e "s/KEY',[ ]*/KEY=/g" /tmp/wp-salts && rm /tmp/wp-salts.bak
	@cat /tmp/wp-salts
	@echo ""
	# now, on your local machine, change directory to your new wordpress app, and push it up
	@echo ""
	@echo "cd $(APP_NAME)"
	@echo "git push dokku master"
