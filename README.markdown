# WordPress on Dokku

A repository to help you setup WordPress on a Dokku server.

## Requirements

- A Dokku server. Tested on 0.7.2+
- The [dokku-mysql](https://github.com/dokku/dokku-mysql) plugin
- `make` installed locally

## Usage

This repository generates an app directory based on environment variables, as well as instructions for configuring your app on the Dokku server.

> Plugins and Uploads will be stored on the host using persistent storage. Unless you do similar with themes, this setup will expect them to be distributed with the wordpress installation.

To use, run the following (and then read the instructions!):

```shell
# both APP_NAME and SERVER_NAME are required
# export the server name (or ip)
export SERVER_NAME=dokku.me

# export the app name
export APP_NAME=blog

# generate the repository and follow the output directions
make build
```

You can also specify a custom WordPress version:

```shell
export WORDPRESS_VERSION=3.7.16

make build APP_NAME=blog SERVER_NAME=dokku.me
```

Finally, while we peg the mysql image version to `5.6.34`, you can also customize that.

```shell
export MYSQL_IMAGE_VERSION=5.6.33

make build APP_NAME=blog SERVER_NAME=dokku.me
```

> As of 2016-11-20, WordPress 3.7.16 and below have issues with MySQL 5.7 and may throw errors during installation. While these *might* be okay to ignore, please keep this in mind before upgrading to a more recent version of MySQL.
