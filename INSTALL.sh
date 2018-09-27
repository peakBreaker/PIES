#!/usr/bin/env bash
# vim: set nowrap:
# vim: set foldmethod=marker

### COMMAND LINE ARGS AND VARIABLES --------------------------------- {{{

while getopts ":a:r:p:hs" o; do case "${o}" in
	h) echo -e "Optional arguments for custom use:\\n  -s simulate the install\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -a: AUR helper (must have pacman-like syntax)\\n  -h: Show this message" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	p) progsfile=${OPTARG} ;;
	a) aurhelper=${OPTARG} ;;
	s) simulated="true" ;;
	*) echo "-$OPTARG is not a valid option." && exit ;;
esac done

# DEFAULTS:
[ -z ${dotfilesrepo+x} ] && dotfilesrepo="https://github.com/peakbreaker/.dotfiles.git"
[ -z ${progsfile+x} ] && progsfile="https://raw.githubusercontent.com/peakBreaker/PIES/master/progs.csv"
[ -z ${aurhelper+x} ] && aurhelper="yay"
[ -z ${simulated+x} ] && simulated="false"

### }}}
## UI Handlers ------------------------------------------------------ {{{

initialcheck() { pacman -S --noconfirm --needed dialog || { echo "Check the following:\\n- Youre running an Arch based distro\\n- Youre running with root privelege\\n- Youre connected to network"; exit; } ;}

preinstallmsg() { \
   dialog --title "Pre-install" --yes-label "Install" --no-label "Exit" --yesno "The install will run with the following configurations: \\n\\n- dotfiles: $dotfilesrepo\\n- Programs file: $progsfile\\n- AurHelper: $aurhelper\\n- Simulated: $simulated" 15 60 || { clear; exit; }
	}

welcomemsg() { \
	dialog --title "Welcome!" --msgbox "Welcome to the peakBreaker autoinstall - This script will install my fully featured development enviroment" 6 60
	}

finalize(){ \
    dialog --title "All done!" --msgbox "Installation finished.  Provided there were no errors, you should now have all packages in $progsfile installed" 6 80
	}

### }}}
### USER MANAGEMENT ------------------------------------------------- {{{

getuserandpass() 
{
	# Prompts user for new username an password.
	# Checks if username is valid and confirms passwd.
	name=$(dialog --inputbox "First, please enter a name for the user account. Curr UID : $EUID" 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	namere="^[a-z_][a-z0-9_-]*$"
	while ! [[ "${name}" =~ ${namere} ]]; do
		name=$(dialog --no-cancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(dialog --no-cancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [[ ${pass1} == ${pass2} ]]; do
		unset pass2
		pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;
}

# Adds user to relevant groups and other user housekeeping
manageuser()
{
    usermod -a -G lp $1
}

### }}}
### INSTALL FUNCTIONS ----------------------------------------------- {{{

# Update the arch package manager keyring
refreshkeys()
{
	dialog --infobox "Refreshing Arch Keyring..." 4 40
	pacman --noconfirm -Sy archlinux-keyring &>/dev/null
}

# Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
putgitrepo()
{ 
	dialog --infobox "Downloading and installing dotfiles..." 4 60

    # Clone git repo to temporary location
	dir=$(mktemp -d)
	chown -R "$name":wheel "$dir"
	sudo -u "$name" git clone --depth 1 "$1" "$dir"/gitrepo &>/dev/null &&
    sudo -u "$name" rm -rf "$dir"/gitrepo/.git

    # Move over the files from the git repo to target
	sudo -u "$name" mkdir -p "$2" &&
	sudo -u "$name" cp -rT "$dir"/gitrepo "$2"
}

# Manual installs from HTTP, used only for AUR helper for now
manualinstall() 
{
	[[ -f /usr/bin/$1 ]] || (
		dialog --infobox "Installing \"$1\", an AUR helper..." 10 60
		cd /tmp
		rm -rf /tmp/"$1"*
		curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
		sudo -u "$name" tar -xvf "$1".tar.gz &>/dev/null &&
		cd "$1" &&
		sudo -u $name makepkg --noconfirm -si &>/dev/null
		cd /tmp) ;
}

# Installs from AUR
aurinstall() 
{
	dialog --title "LARBS Installation" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2." 5 70
	grep "^$1$" <<< "$aurinstalled" && return
	sudo -u $name $aurhelper -S --noconfirm "$1" &>/dev/null
}

# Function for installing from package repos
maininstall() 
{
	dialog --title "PIES Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2." 5 70
    if [ $simulated = "false" ]; then
	    pacman --noconfirm --needed -S "$1" &>/dev/null
    else
        sleep 2
    fi
}

# Main install function for packages
installationloop() 
{
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qm | awk '{print $1}')
	while IFS=, read -r tag program comment; do
      n=$((n+1))
      case "$tag" in
        "") maininstall "$program" "$comment" ;;
        "C") echo "Skipping comment --" ;;
        "A") aurinstall "$program" "$comment" ;;
        "G") gitmakeinstall "$program" "$comment" ;;
      esac
	done < /tmp/progs.csv ;
}

### }}}
### Actual Procedure calls ------------------------------------------ {{{

# Check if user is root on Arch distro. Install dialog.
initialcheck

# Welcome user.
welcomemsg || { clear; exit; }

# Last chance for user to back out before install.
preinstallmsg || { clear; exit; }

# User management
if [ $(logname) = "root" ]; then
    # Means we're root - prompt username & pass
    getuserandpass
    # Give warning if user already exists.
    usercheck || { clear; exit; }
else
    # means we're running as sudo, get curr username
    name=$(logname)
fi
manageuser $name

# Make sure we have aurhelper installed
manualinstall $aurhelper

# Installs programs
installationloop

# Install the dotfiles in the user's home directory
putgitrepo "$dotfilesrepo" "/home/$name"

# Make pacman and yay colorful because why not.
sed -i "s/#Color^/Color/g" /etc/pacman.conf

# Last message! Install complete!
finalize
clear

### }}}
