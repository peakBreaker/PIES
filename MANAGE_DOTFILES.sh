#!/usr/bin/env bash

# Goes into all versioncontrolled repos and updates them to newest version
updategitrepo()
{
    [[ $devmode = "false" ]] && dialog --infobox "Updating $1 ..." 4 60
    [[ $devmode = "true" ]] && echo -e -n "\t -- Updating $1 ..."

    cd $(echo $1 | sed 's/"//g') &>/dev/null
    git stash &>/dev/null &&
    git checkout master &>/dev/null &&
    git pull &>/dev/null &&
    git stash pop &>/dev/null
    cd - &>/dev/null

    [[ $devmode = "true" ]] && echo "OK!"
}

# Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
putgitrepo()
{
    [[ $devmode = "false" ]] && dialog --infobox "Downloading and installing $2..." 4 60
    [[ $devmode = "true" ]] && echo -e "\t -- Downloading and installing $2..."

    # Clone git repo to temporary location
    dir=$(mktemp -d)
    chown -R "$name":wheel "$dir"
    sudo -u "$name" git clone --depth 1 "$1" "$dir"/gitrepo &>/dev/null # &&
    #sudo -u "$name" rm -rf "$dir"/gitrepo/.git

    # Move over the files from the git repo to target
    sudo -u "$name" mkdir -p "$2" &&
    sudo -u "$name" cp -rT "$dir"/gitrepo "$2"
}

# Either installs or updates the repos on the system
managedotfiles() {
    [[ -d "/home/$name/.git" ]] && DOTFILES_INSTALLED="true"
    if [ "$DOTFILES_INSTALLED" = "true" ]
    then
        echo "DOTFILES: Already installed - running full update"
        # Install the dotfiles in the user's home directory
        updategitrepo "$dotfilesfolder"
        # Install terminal, firefox config and add blog repo
        updategitrepo "$mozillafolder"
        updategitrepo "$blogfolder"
        updategitrepo "$termfolder" && 
          sudo make clean install --directory=$(echo $termfolder | sed 's/"//g') &> /dev/null
        echo "DOTFILES: Update complete"
    else
        echo "DOTFILES: Installing dotfiles"
        # Install the dotfiles in the user's home directory
        putgitrepo "$dotfilesrepo" "$dotfilesfolder"
        # Install terminal, firefox config and add blog repo
        putgitrepo "$mozillarepo" "$mozillafolder"
        putgitrepo "$blogrepo" "$blogfolder"
        putgitrepo "$termrepo" "$termfolder" && 
        sudo make clean install --directory=$(echo $termfolder | sed 's/"//g') &> /dev/null
        echo "DOTFILES: Install complete!"
    fi
}

[ -z ${name} ] && export name=$(whoami) && echo "Set name to $name"
. loadconfig.sh && loadconfig config.ini
[ -z ${devmode+x} ] && devmode="true"
managedotfiles
