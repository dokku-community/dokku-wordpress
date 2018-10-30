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

## After Installation (Optional)

### Modify Upload File Size Limit

Put `.user.ini` file at the root of your folder with the following content:

```
upload_max_filesize = 256M
post_max_size = 256M
```

Then use the following command to push to dokku

```shell
git add .
git commit -m "Modify Upload File Size Limit"
git push dokku master
```

### Upgrading Wordpress

To upgrade to a later version of Wordpress, pull the later version of wordpress 
into your generated local repo and push it.  For example, to upgrade the 
dokku-wordpress generated 
app `mywp` to version 4.9.8 of Wordpress:

```
cd mywp
git remote set-branches --add origin 4.9.8
git fetch origin 4.9.8:latest
git merge -X theirs latest
```

If you get any conflicts `git merge-tool` and answer "d" (to delete) for each 
file in conflict, if any. Then git commit to complete the merge.

`git push dokku master`

Warning: A 'traditional' upgrade performed using Wordpress's own UI based upgrade process will not 
survive a server app restart (due to the ephemeral nature of the underlying docker 
based filesystem) and thus should not be attempted if you want to persist the upgrade.

### Plugins

Plugins stored in `wp-content/plugins` and uploads stored in `wp-content/uploads` are 
given special persistence via the `dokku storage:mount` commands in this installation process.
 
Plugins should thus be installed via Wordpress's own UI based installation method and
will persist across remote reboots and won't get affected by subsequent git pushes 
when upgrading.
Manual installation by copying plugins into the local git repo and pushing them up 
will not work.

### Themes
 
The `wp-content/themes` directory is not given any special persistence on the remote server.
So whilst there is persistence whilst the Wordpress app is running and themes 
will successfully install - any such new themes or theme customisations will not survive a 
remote app restart/server reboot.  Thus any custom themes should be copied 
into `wp-content/themes` in the local git repo and pushed up.  

Tip: It can be tricky to view the state of the filesystem that your wordpress app 
actually resides in, because of the layered nature of the underlying docker filesystem.
To view the actual filesystem of your wordpress app 'mywp' on server 'dokku.me': ssh into
your server e.g. `ssh root@dokku.me` then `dokku run mywp bash` then `ls /app/wp-content/`. 
Alternatively install a Wordpress  
[file manager plugin](https://wordpress.org/plugins/wp-file-manager/) to view and 
download new/customised theme files on the remote server and into your local repo. 

When upgrading using the above Wordpress upgrade instructions - any custom themes 
in the local repository will be deleted in order to synchronise perfectly with the 
fresh new version of Wordpress.
To preserve extra/customised themes back them up before upgrading the local repo
and restore them into the local `wp-content/themes` directory after the upgrade. 
Alternatively do not delete the files you want to keep during the `git merge-tool` step of the 
local upgrade process - though be careful as you probably want to replace 
default themes to be compatible with the new upgraded version of Wordpress.     
