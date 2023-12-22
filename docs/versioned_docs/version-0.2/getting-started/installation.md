---
title: Installation
description: Get started by installing Marten and its dependencies.
---


This guide will help you get started in order to install Marten and its dependencies. Let's get started!

## Install Crystal

Marten is a Crystal web framework; as such Crystal must be installed on your system. There are many ways to install Crystal, but we'll only highlight what we think are the most common ones here for the sake of simplicity: using Homebrew (macOS or Linux) or the APT package manager (Ubuntu, Debian). Please refer to the official [Crystal installation guide](https://crystal-lang.org/install/) if these methods don't work for you.

### Using Homebrew

On macOS or Linux, Crystal can be installed using [Homebrew](https://brew.sh/) (also known as Linuxbrew) by running the following command:

```bash
brew install crystal
```

### Using APT

On Ubuntu, Debian or any other Linux distribution using the APT package manager, Crystal can be installed by running the following command:

```bash
curl -fsSL https://crystal-lang.org/install.sh | sudo bash
```

## Install a database

New Marten projects will use a SQLite database by default: this lightweight serverless database application is usually already pre-installed on most of the existing operating systems, which makes it an ideal candidate for a development or a testing database. As such, if you choose to use SQLite for your new Marten project, you can very probably skip this section. 

Marten also has built-in support for PostgreSQL and MySQL. Please refer to the applicable official documentation to install your database of choice:

* [PostgreSQL Installation Guide](https://wiki.postgresql.org/wiki/Detailed_installation_guides)
* [MySQL Installation Guide](https://dev.mysql.com/doc/refman/8.0/en/installing.html)
* [SQLite Installation Guide](https://www.tutorialspoint.com/sqlite/sqlite_installation.htm)

Each database requires the use of a dedicated shard (package of Crystal code). You don't have to install any of these right now if you are just starting with the framework or if you are planning to follow the [tutorial](./tutorial.md), but you may have to add one of the following entries to your project's `shard.yml` file later:

* [crystal-pg](https://github.com/will/crystal-pg) (needed when using PostgreSQL databases)
* [crystal-mysql](https://github.com/crystal-lang/crystal-mysql) (needed when using MySQL databases)
* [crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) (needed when using SQLite3 databases)

## Install Marten

The next step is to install the Marten CLI. This tool will let you easily generate new Marten projects or applications.

### Using Homebrew

On macOS or Linux, Marten can be installed using [Homebrew](https://brew.sh/) (also known as Linuxbrew) by running the following commands:

```bash
brew tap martenframework/marten
brew install marten
```

Once the installation is complete, you should be able to use the `marten` command:

```bash
marten -v
```

### From the sources

Marten can be installed from the sources by running the following commands:

```bash
git clone --branch v0.2.x https://github.com/martenframework/marten
cd marten
shards install
crystal build src/marten_cli.cr -o bin/marten
mv bin/marten /usr/local/bin
```

Once the above steps are done, you should be able to verify that the `marten` command works as expected by running:

```bash
marten -v
```

## Next steps

_Congrats! You’re in._

You can now move on to the [introduction tutorial](./tutorial.md).
