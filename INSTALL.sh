#!/usr/bin/env bash
# vim: set nowrap:
# vim: set foldmethod=marker

### COMMAND LINE ARGS AND VARIABLES --------------------------------- {{{
while getopts ":a:r:p:sdh" o; do case "${o}" in
	h) echo -e "Optional arguments for custom use:\\n  -s simulate the install\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -a: AUR helper (must have pacman-like syntax)\\n  -d: enable devmode (no ncurses)\\n  -h: Show this message" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	p) progsfile=${OPTARG} ;;
	a) aurhelper=${OPTARG} ;;
	s) simulated="true" ;;
	d) devmode="true" ;;
	*) echo "-$OPTARG is not a valid option." && exit ;;
esac done

# DEFAULTS:
[ -z ${dotfilesrepo+x} ] && dotfilesrepo="https://github.com/peakbreaker/.dotfiles.git"
[ -z ${mozillarepo+x} ] && mozillarepo="https://github.com/peakbreaker/firepies.git"
[ -z ${termrepo+x} ] && termrepo="https://github.com/peakbreaker/st.git"
[ -z ${termfolder+x} ] && termfolder="/home/$name/Documents/Personal/st"
[ -z ${progsfile+x} ] && progsfile="https://raw.githubusercontent.com/peakBreaker/PIES/master/progs.csv"
[ -z ${aurhelper+x} ] && aurhelper="yay"
[ -z ${simulated+x} ] && simulated="false"
[ -z ${devmode+x} ] && devmode="false"
[ -z ${piesfolder+x} ] && piesfolder=$(pwd)

echo "devmode is : $devmode"
[[ $devmode = "true" ]] && echo "devmode is enabled!"

### }}}
## UI Handlers ------------------------------------------------------ {{{

initialcheck() { pacman -S --noconfirm --needed dialog || { echo -e "Check the following:\\n- Youre running an Arch based distro\\n- Youre running with root privelege\\n- Youre connected to network"; exit; } ; }

preinstallmsg() {
    [[ $devmode = "false" ]] && dialog --title "Pre-install" --yes-label "Install" --no-label "Exit" --yesno "The install will run with the following configurations: \\n\\n- dotfiles: $dotfilesrepo\\n- Programs file: $progsfile\\n- AurHelper: $aurhelper\\n- Simulated: $simulated" 15 60 && return
    [[ $devmode = "true" ]] && echo -e "The install will run with the following configurations: \\n\\n- dotfiles: $dotfilesrepo\\n- Programs file: $progsfile\\n- AurHelper: $aurhelper\\n- Simulated: $simulated" 
    #[[ $devmode = "true" ]] && read "Press any key to continue"
}

welcomemsg() {
    [[ $devmode = "false" ]] && dialog --title "Welcome!" --msgbox "Welcome to the peakBreaker autoinstall - This script will install my fully featured development enviroment" 6 60 && return
    [[ $devmode = "true" ]] && echo "Welcome to this PIES development environment install!"
}

finalize() {
    [[ $devmode = "false" ]] && dialog --title "All done!" --msgbox "Installation finished.  Provided there were no errors, you should now have all packages in $progsfile installed" 6 80 && return
    [[ $devmode = "true" ]] && echo "Installation finished.  Provided there were no errors, you should now have all packages in $progsfile installed" 
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
manageuser() {
    usermod -a -G lp $1
    usermod -a -G docker $1
}

### }}}
### INSTALL FUNCTIONS ----------------------------------------------- {{{

# Update the arch package manager keyring
refreshkeys()
{
	[[ $devmode = "false" ]] && dialog --infobox "Refreshing Arch Keyring..." 4 40
	pacman --noconfirm -Sy archlinux-keyring &>/dev/null
}

# Manual installs from HTTP, used only for AUR helper for now
manualinstall() 
{
	[[ -f /usr/bin/$1 ]] || (
		[[ $devmode = "false" ]] && dialog --infobox "Installing \"$1\", an AUR helper..." 10 60
		[[ $devmode = "true" ]] && echo "Installing AUR helper : $1.."
		cd /tmp
		rm -rf /tmp/$1*
		[[ $devmode = "true" ]] && echo "Cleared the directory for download - proceeding to fetch AUR helper with http"

		curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz && \
		sudo -u "$name" tar -xvf "$1".tar.gz &>/dev/null && \
		cd "$1" && \
		sudo -u $name makepkg --noconfirm -si &>/dev/null \
		cd /tmp) ;
}

# Installs from AUR
aurinstall() 
{
	[[ $devmode = "false" ]] && dialog --title "PIES Installation : $title" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2." 5 70
    [[ $devmode = "true" ]] && echo -e "$title : Installing \`$1\` ($n of $total) from the AUR. $1 | $2." 
	grep "^$1$" <<< "$aurinstalled" && return
	sudo -u $name $aurhelper -S --noconfirm "$1" &>/dev/null
}

# Function for installing from package repos
maininstall() 
{
    [[ $devmode = "false" ]] && dialog --title "PIES Installation : $title" --infobox "Installing \`$1\` ($n of $total). $1 $2." 5 70
    [[ $devmode = "true" ]] && echo -e "$title : Installing \`$1\` ($n of $total). $1 | $2." 
    if [ $simulated = "true" ]; then
       sleep 1
    else
      [[ $devmode = "false" ]] && pacman --noconfirm --needed -S "$1" &>/dev/null
      [[ $devmode = "true" ]] && pacman --noconfirm --needed -S "$1"
    fi
}

# Main install function for packages
installationloop() 
{
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qm | awk '{print $1}')
    title="INSTALL"
	while IFS=, read -r tag program comment; do
      n=$((n+1))
      case "$tag" in
        "") [ ! "$program" ] || maininstall "$program" "$comment" ;;
        "C") echo "Section : $program" ; title="\t -- $program" ;;
        "A") aurinstall "$program" "$comment" ;;
        "G") gitmakeinstall "$program" "$comment" ;;
      esac
	done < /tmp/progs.csv ;
}

# Some additional special installs
additionalinstalls()
{
    # Install oh my zsh
    [[ $devmode = "false" ]] && dialog --title "Additional Installation" --infobox "Installing oh-my-zsh through https" 5 70
    [[ $devmode = "true" ]] && echo "Installing oh-my-zsh through https"
    sudo -H -u $name sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
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
if [ $(logname) = "root" ]; then
    # Means we're root - prompt username & pass
    getuserandpass
    # Give warning if user already exists.
    usercheck || { clear; exit; }
else
    # means we're running as sudo, get curr username
    name=$(logname)
fi
export name=$name

manageuser $name
[[ -z $devmode ]] && dialog --title "Usercheck" --msgbox "Proceeding to install for user : $name" 6 60 || echo "Proceeding to install for user : $name"

# Make sure we have aurhelper installed
manualinstall $aurhelper

# Installs programs
installationloop

# Additional installs
additionalinstalls

# Install the git repos
echo "proceeding to manage git repositories"
$piesfolder/MANAGE_DOTFILES.sh

# Enable services
sudo systemctl enable bluetooth.service

# Make pacman and yay colorful because why not.
sed -i "s/#Color^/Color/g" /etc/pacman.conf

# Last message! Install complete!
finalize
[[ $devmode = "false" ]] && clear
### }}}
