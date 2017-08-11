
# hiera_sqlserver

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with hiera_sqlserver](#setup)
    * [Automatic Setup](#automatic-setup)
    * [Manual Setup](#manual-setup)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module provides a hiera backend for integration with MS SQL Databases. This utilizes a few different external tools to be able to accomplish this goal.
1. [jdbc-sqlserver](https://rubygems.org/gems/jdbc-sqlserver/versions/0.0.2)
2. [tiny_tds](https://github.com/rails-sqlserver/tiny_tds)
3. [freetds](http://www.freetds.org/)

Overall the structure of this backend follows a lot of the implementation decisions of the [hiera-mysql](https://github.com/crayfishx/hiera-mysql) by crayfishx but is simply modified for use with MS SQL Server instances.

## Setup

### Automatic Setup

If using PE, there is a class that will handle the installation of the appropriate dependencies and gems for you automatically. This currently has only been developed for CentOS/RedHat 7 though other platforms will be added in the future.

Make sure to classify the Puppet Master with this configuration.

```puppet
include hiera_sqlserver
```

### Manual Setup

If you would like to set this up manually there are a few steps. The first will be getting puppetserver enabled for using this backend and that step requires installing jdbc-sqlserver into the puppetserver ruby context.

```bash
/opt/puppetlabs/bin/puppetserver gem install jdbc-sqlserver
```
Make sure to restart Puppetserver after this.

```bash
service pe-puppetserver restart
```
**NOTE:** This will ensure that the required gems are installed in puppetserver's jruby environment, but for cli based troubleshooting or hiera useage we need to do a few more installation steps.

This module currently assumes that you will be using the freetds provided by the system. As such, you should make sure you have freetds installed on your system with something like the following.

```bash
yum install freetds freetds-devel
```
Afterwards, you will need to install tiny_tds. I have tested against an older version, 0.7.0, but more modern versions may be able to be used. For example on Puppet Platform 5 which uses more modern ruby versions the latest may be able to be used easily.

```bash
/opt/puppetlabs/puppet/bin/gem install tiny_tds -v '0.7.0' -- --enable-system-freetds
```

## Usage

This is an example hiera.yaml (version 3) configuration

```
---
:backends:
- yaml
- sqlserver

:hierarchy:
  - secure
  - "nodes/%{hostname}"
  - "location/%{location}"
  - common


:yaml:
  :datadir: "/etc/puppetlabs/code/environments/%{environment}/hieradata"

:sqlserver:
  :host: 192.168.2.219
  :user: sa
  :pass: Ub3rS3cr3+
  :database: configdata
  :instance: MYINSTANCE

  :query: SELECT val FROM configdata1 WHERE var='%{key}' AND environment='%{environment}'

:logger: console
```

## Reference

Users need a complete list of your module's classes, types, defined types providers, facts, and functions, along with the parameters for each. You can provide this list either via Puppet Strings code comments or as a complete list in the README Reference section.

* If you are using Puppet Strings code comments, this Reference section should include Strings information so that your users know how to access your documentation.

* If you are not using Puppet Strings, include a list of all of your classes, defined types, and so on, along with their parameters. Each element in this listing should include:

  * The data type, if applicable.
  * A description of what the element does.
  * Valid values, if the data type doesn't make it obvious.
  * Default value, if any.

## Limitations

This is where you list OS compatibility, version compatibility, etc. If there are Known Issues, you might want to include them under their own heading here.

## Development

Since your module is awesome, other users will want to play with it. Let them know what the ground rules for contributing are.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header. 
