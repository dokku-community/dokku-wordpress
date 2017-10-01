# WordPress on Dokku

A repository to help you setup WordPress on a Dokku server.

## Requirements

- A Dokku server. Tested on 0.7.2+
- The [dokku-mysql](https://github.com/dokku/dokku-mysql) or [dokku-mariadb](https://github.com/dokku/dokku-mariadb) plugin
- `make` installed locally
- `curl` or `wget` installed locally

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

Want a mostly unattended installation? You can also execute it with the `UNATTENDED_CREATION` environment variable. You will only need to create the requisite persistent storage directories and push the repository. All configuration will be manually performed using the `dokku` user against the configured `SERVER_NAME`.

```shell
export UNATTENDED_CREATION=1

make build APP_NAME=blog SERVER_NAME=dokku.me
```

You can also destroy an existing wordpress installation:

```shell
make destroy APP_NAME=blog SERVER_NAME=dokku.me UNATTENDED_CREATION=1
```
