# Peakbreaker Install Endless Scripts (PIES)

**Basically this is a repo for autoinstalling packages and whatnot**

I ran out of patience with configuration of my development enviroment, so I sat
down, researched what other clever people are doing, and started outlining how
I want my automatic installs to be.  Basically my devenv is split in two:

- PIES for scripts and automatic installations of stuff
- .dotfiles for all configuration files, no scripts

My goal is to sit back and let my scripts do all the work of setting up my
system for me.

![PIES](./PIES.png)

## Getting started

### Prereq
- Arch Linux based system
- Root priveleges
- Internet access

### Instructions

1. Run the install script as sudo user:
```
$ sudo bash $(curl -L https://raw.githubusercontent.com/peakBreaker/PIES/master/INSTALL.sh)
```
2. Install [st]
3. Install the dotfiles for [firefox]
4. Create SSH keypair: `ssh-keygen -t rsa -b 4096`
5. Enable services:
```
$ sudo systemctl enable docker
$ sudo systemctl start docker
```
6. Install vim plugins.  Enter vim and write `:PlugInstall`. Compile YCM by
   running install.py

### FAQ

- `command not found: print_icon`: Check locale settings
