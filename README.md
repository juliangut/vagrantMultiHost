# Vagrant Multiple Hosts configuration

Configure multiple hosts with one *YAML* file

*Based on [laravel/homestead](https://github.com/laravel/homestead) configuration*

## Introduction

laravel/homestead allows you to define a single host automatically configured with nginx, mysql and blackfire, but if you want to have more than one host, for example one for web and another for the ddbb it is not possible

Using this repository you can define as many hosts as you want in a single YAML file and let Vagrant configure them

## Usage

Include the repository into your project by `git submodule` it and copy required files out to your project

```
git submodule init
git submodule add git@github.com:juliangut/vagrantMultiHost.git vagrant
cp ./vagrant/Vagrantfile ./
cp ./vagrant/Hosts.yaml ./
```

Now you should have a `./vagrant` directory and two files in your project root directory

Update `Hosts.yaml` with your hosts configurations and you are ready to start using vagrant

```
vagrant status
vagrant up <host_name>
```

## Hosts configuration

Review laravel/homestead [documentation](http://laravel.com/docs/5.0/homestead) for rest of available configuration options

### boxes

You can define your own named boxes providing a name and url to the box file. This is handly for example if you use private company boxes.

### path

Is the path to this git module directory, normally if you didn't change directory name on `git submodule add` you should leave this configuration untouched

### name

Each host has a name that will be used on the command line to interact with the host

```
vagrant up web
vagrant destroy ddbb
```

### identifier

Is the name of the virtual machine in VirtualBox

### autostart

Every hosts setting autostart to true will be automatically started with `vagran up` without asking for a host name. By default all hosts are set to autostart false

### box

The name of the box to use, can be any of default vagrant boxes (defaults to laravel/homestead) or one of your previously named boxes

### ip

Virtual machine's ip, if none provided ips will be given secuentially per host starting on 192.168.10.101

### provider

Lets you configure each virtual machine independently. Review Vagrant [documentation](https://docs.vagrantup.com/v2/virtualbox/configuration.html) for VirtualBox configurations

### provision

List all your custom bash scripts you want to use to provide the box

## License

### Release under BSD-3-Clause License.

See file [LICENSE](https://github.com/juliangut/vagrantMultiHost/blob/master/LICENSE) included with the source code for a copy of the license terms
