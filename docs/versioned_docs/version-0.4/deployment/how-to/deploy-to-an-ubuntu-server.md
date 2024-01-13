---
title: Deploy to an Ubuntu server
description: Learn how to deploy a Marten project to an Ubuntu server.
---

This guide covers how to deploy a Marten project to an Ubuntu server.

## Prerequisites

To complete the steps in this guide, you will need:

* an [Ubuntu](https://ubuntu.com) server with SSH access and `sudo` permissions
* a working Marten project
* a domain name targeting your server

## Install the required dependencies

The first dependency we want to install on the server is Crystal itself. To do so, you can run the following command:

```bash
curl -fsSL https://crystal-lang.org/install.sh | sudo bash
```

:::tip
Alternatively, you can also refer to [Crystal's official installation instructions](https://crystal-lang.org/install/on_ubuntu/) for Ubuntu if the above command does not work.
:::

Secondly, we should install a few additional packages that will be required later on:

* `git` to clone the project's repository
* `nginx` to serve the project's server behind a reverse proxy and also serve [assets](../../assets/introduction.md) and [media files](../../files/managing-files.md)
* `postgresql` to handle our database needs

This can be achieved by running the following command:

```bash
sudo apt-get install git nginx postgresql
```

:::info
This guide assumes the use of [PostgreSQL](https://www.postgresql.org) but can easily be adapted if your project requires another database backend.
:::

## Create a deployment user

Let's now create a deployment user. This user will have access to your project's server and will be used to run the application:

```bash
sudo adduser --disabled-login deploy
```

## Create the project folders

We can now create a deployment folder where we will be able to clone the project repository later on, and store collected assets or media files if necessary. While creating this folder, it is also necessary to ensure that the `deploy` user created previously has access to it:

```bash
sudo mkdir /srv/<yourapp>
sudo chown deploy:deploy /srv/<yourapp>
```

## Create a database

As mentioned previously, this guide assumes the use of [PostgreSQL](https://www.postgresql.org) for the project's database. As such, we need to create a database user and the database itself. To do so, we will need to execute the following commands:

```bash
su - postgres -c 'createuser deploy'
su - postgres -c 'createdb -O deploy <yourapp>'
```

:::info
PostgreSQL management commands are usually performed as the `postgres` user, hence the use of `su` in the above commands.
:::

Obviously, you should also ensure that your Marten project is correctly configured to target this database in production. You can have a look at the [database settings](../../development/reference/settings.md#database-settings) to see what are the available options when it comes to configuring databases.

## Clone the project

First, change into the `deploy` user you created previously:

```bash
su - deploy
```

Then you can clone your repository and change into the corresponding folder using the following commands:

```bash
git clone <yourgiturl> /srv/<yourapp>/project
cd /srv/<yourapp>/project
```

## Install the dependencies and compile the project

The next step is to install your project's dependencies. To do so, you can use the [`shards`](https://crystal-lang.org/reference/man/shards/index.html) command as follows:

```bash
shards install
```

We then need to compile the project binary and the [management CLI](../../development/management-commands.md):

```bash
crystal build src/server.cr -o bin/server --release
crystal build manage.cr -o bin/manage --release
```

The management CLI binary will be helpful in order to [apply migrations](../../models-and-databases/migrations.md) and to [collect assets](../../development/reference/management-commands.md#collectassets).

:::info
Depending on how you are handling assets as part of your projects you may have to perform additional steps. For example, you may have to install Node.js, install additional dependencies, and eventually bundle assets with Webpack if this is applicable to your project!
:::

## Collect assets

You will then want to collect your [assets](../../assets/introduction.md) so that they are uploaded to their final destination. To do so you can leverage the management CLI binary you compiled previously and run the [`collectassets`](../../development/reference/management-commands.md#collectassets) command:

```bash
bin/manage collectassets --no-input
```

This management command will "collect" all the available assets from the applications' assets directories and from the directories configured in the [`dirs`](../../development/reference/settings.md#dirs) setting, and ensure that they are "uploaded" to their final destination based on the [assets storage](../../assets/introduction.md#assets-storage) that is currently configured.

## Apply the project's migrations

Then you will want to run your project's [migrations](../../models-and-databases/migrations.md) to ensure that your models are created at the database level. To achieve this you can leverage the management CLI binary that you compiled in a previous step and run the [`migrate`](../../development/reference/management-commands.md#migrate) command:

```bash
bin/manage migrate
```

## Setup a SystemD service for your application

[SystemD](https://systemd.io) is a service manager for Linux that we can leverage in order to easily start or restart our deployed application. As such, we are going to create a service for our application.

To do so, first ensure that you exit your current shell session as the `deploy` user with `Ctrl-D` or by entering the `exit` command. Then create a service file for your app by typing the following command:

```bash
nano /etc/systemd/system/<yourapp>.service
```

This should open a text editor in your terminal. Copy the following content into it:

```
[Unit]
Description=<yourapp> server
After=syslog.target

[Service]
ExecStart=/srv/<yourapp>/project/bin/server
Restart=always
RestartSec=5s
KillSignal=SIGQUIT
WorkingDirectory=/srv/<yourapp>/project
Environment="MARTEN_ENV=production"

[Install]
WantedBy=multi-user.target
```

Don't forget to replace the `<yourapp>` placeholders with the right values and, when ready, save the file using `Ctrl-X` and `y`.

As you can see in the above snippet, we are assuming that the current [Marten environment](../../development/settings.md#environments) is the production one by setting the `MARTEN_ENV` environment variable to `production`. You should adapt this to your deployment use case obviously.

:::tip
This service file is also a good place to define any environment variables that may be required by your project's settings. For example, this may be the case for "sensitive" setting values such as the [`secret_key`](../../development/reference/settings.md#secret_key) setting: as highlighted in [Secure critical setting values](../introduction.md#secret-key) you could store the value of this setting in a dedicated environment variable and load it from your application's codebase. If you do so, you will also want to add additional lines to the service file in order to define these additional environment variables. For example:

```
Environment="MARTEN_SECRET_KEY=<secretkey>"
```
:::

In order to ensure that SystemD takes into account the new service you just created, you can then run the following command:

```bash
systemctl daemon-reload
```

And finally, you can start your server with:

```bash
service <yourapp> start
```

Note that in subsequent deployments you will simply want to restart the SystemD service you previously defined. To do so, you can simply use the following command:

```bash
service <yourapp> restart
```

## Setup a Nginx reverse proxy

Marten project servers are intended to be used behind a reverse proxy such as [Nginx](https://www.nginx.com/) or [Apache](https://httpd.apache.org/). Using a reverse proxy allows you to easily set up an SSL certificate for your server (for example using [Let's Encrypt](https://letsencrypt.org/)), to serve collected assets and media files if applicable, and enhance security and reliability.

In our case, we will be using [Nginx](https://www.nginx.com/) and create a site configuration for our application. Let's use the following command to do so:

```bash
nano /etc/nginx/sites-available/<yourapp>.conf
```

This should open a text editor in your terminal. Copy the following content into it:

```
server {
  listen 80;
  server_name <yourdomain>;

  include snippets/snakeoil.conf;

  gzip on;
  gzip_disable "msie6";
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_min_length 256;
  gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

  error_log /var/log/nginx/<yourapp>_error.log;
  access_log /var/log/nginx/<yourapp>_access.log;

  location /assets/ {
    expires 365d;
    alias <yourassetspath>/;
  }

  location /media/ {
    alias <yourmediapath>/;
  }

  location / {
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;
    proxy_buffering off;

    proxy_pass http://localhost:<yourport>;
  }
}
```

Don't forget to replace the `<yourapp>`, `<yourdomain>`, `<yourassetspath>`, `<yourmediapath>`, and `<yourport>` placeholders with the right values and, when ready, save the file using `Ctrl-X` and `y`.

As you can see, the reverse proxy will serve our application on the HTTP port 80 and is configured to target our Marten server host (`localhost`) and port. Because of this, you should ensure that your Marten server is not using the HTTP port 80 (instead it could use something like 8080 or 8000 for example).

You should also note that the above configuration defines two additional locations in order to serve assets (`/assets/`) and media files (`/media/`). This makes the assumption that those files are _locally_ available on the considered server. As such you should remove these lines if this is not applicable to your use case or if these files are uploaded somewhere else (eg. in a cloud bucket).

You can then enable this site configuration by creating a symbolic link as follows:

```bash
ln -s /etc/nginx/sites-available/<yourapp>.conf /etc/nginx/sites-enabled/<yourapp>.conf
```

And finally, you can restart the Nginx service with:

```bash
sudo service nginx restart
```
