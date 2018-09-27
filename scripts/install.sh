#!/usr/bin/env bash
# vim: set foldmethod=marker:
echo -n '\e[32m'
echo "                   _    ____                 _             "
echo "                  | |  |  _ \               | |            "
echo "  _ __   ___  __ _| | _| |_) |_ __ ___  __ _| | _____ _ __ "
echo " | '_ \ / _ \/ _\` | |/ /  _ <| '__/ _ \\/ _\` | |/ / _ \ '__|"
echo " | |_) |  __/ (_| |   <| |_) | | |  __/ (_| |   <  __/ |   "
echo " | .__/ \___|\__,_|_|\_\____/|_|  \___|\__,_|_|\_\___|_|   "
echo " | |                                                       "
echo " |_|                                                       "
echo ""
echo -n '\e[37m'
echo "--- Welcome to my dotfiles repo for autoinstalling devenv ---"

# BASIC CONFIGS ----------------------------------------------- {{{
## Some configs for the script exec
dotfiles=".spacemacs .zshrc .Xresources .gitconfig .vimrc .urxvt"
dotconfigs="ranger"


## Get basedir and run the script
BASEDIR="$( cd "$(dirname "$0")/.." ; pwd -P )"
. $BASEDIR/scripts/scriptutils.sh # Contains debugging utils
INFO "BASEDIR IS :: " $BASEDIR

# }}}

## Get the OS distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
  echo "DETECTED OS :: $NAME"
  # Optionally add config file here or similar
else
  echo "FOUND NO OS FILE"
  exit -1
fi


# Install packages
read -p "Install packages? Y/n " option
echo
case "$option" in y|Y ) echo "INSTALLING PACKAGES FOR OS ID :: $OS";

  while read p; do
    ## Check for comment
    if [[ "$p" =~ ^#+ ]]; then
      echo "found commented line: $p"
      continue
    fi
    ## Check OS for package manager
    if [ $OS=arch ]; then
      sudo pacman -S --needed --noconfirm $p
    else
        echo "OS NOT SET -- NO PACKAGES TO INSTALL"
    fi
  done<$BASEDIR/scripts/${OS}_packages.list
esac


read -p "Create symlinks to .dotfiles? Y/n " option
echo
case "$option" in y|Y ) echo "\t\t-- CREATING LINKS TO DOTCONFIGS!";
	INFO "Creating symlinks for single dotfiles"

	# Install dotfiles
	for dotfile in $dotfiles; do
	  INFO "Installing $dotfile ...."
	  ln -svf "$BASEDIR/files/$dotfile" "$HOME/${dotfile##*/}" 2>&1
	  SUCCESS "Successfully installed dotfile :: $dotfile ! \n"
	done
esac
echo

# Install the .config
read -p "Install .config files? Y/n " option
echo
case "$option" in
    y|Y ) echo "Yes";
    
    INFO "Creating symlinks for files in .config directory"
    # Link the dotfiles
    for dotconfig in $dotconfigs; do
        INFO "Installing $dotconfig ...."
        ln -svf $BASEDIR/.config/$dotconfig/* $HOME/.config/$dotconfig/ 2>&1
        SUCCESS "Successfully installed dotfiles from :: $dotconfig ! \n"
    done
esac
echo
