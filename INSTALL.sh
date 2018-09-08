#!/USR/BIn/env bash
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
   dialog --title "Pre-install" --yes-label "Install" --no-label "Exit" --yesno "The install will run with the following configurations: \\n\\n- dotfiles: $dotfilesrepo\\n- Programs file: $progsfile\\n- AurHelper: $aurhelper\\n- Simulated: $simulated" 10 60 || { clear; exit; }
	}

welcomemsg() { \
	dialog --title "Welcome!" --msgbox "Welcome to the peakBreaker autoinstall - This script will install my fully featured development enviroment" 6 60
	}

finalize(){ \
    dialog --title "All done!" --msgbox "Installation finished.  Provided there were no errors, you should now have all packages in $progsfile installed" 6 80
	}

### }}}
### INSTALL FUNCTIONS ----------------------------------------------- {{{

# function for 
maininstall() 
{
	dialog --title "PIES Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2." 5 70
    if [ $simulated = "false" ]; then
	    pacman --noconfirm --needed -S "$1" &>/dev/null
    else
        sleep 2
    fi
}

installationloop() 
{
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qm | awk '{print $1}')
	while IFS=, read -r tag program comment; do
      n=$((n+1))
      case "$tag" in
        "") maininstall "$program" "$comment" ;;
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

# Installs programs
installationloop

# Make pacman and yay colorful because why not.
sed -i "s/#Color^/Color/g" /etc/pacman.conf

# Last message! Install complete!
finalize
clear

### }}}
