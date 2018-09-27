# Start a valid sudo session
sudo -v

# Start by updating and upgrading
sudo apt update
sudo apt upgrade -y

# Essential programs apt-get
sudo apt install -y zsh git keepass2 curl wget xscreensaver emacs

# Set up gopath and install go
mkdir -p ~/Workspace/go-workspace
mkdir -p $HOME/Workspace/go-workspace/src
mkdir -p $HOME/Workspace/go-workspace/pkg
mkdir -p $HOME/Workspace/go-workspace/bin
sudo apt install -y golang-go

# Install python3
sudo apt install -y rlwrap sqlite3 socat
sudo apt install -y python python-pip build-essential python-dev virtualenv

# Install ansible
deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
sudo apt install -y ansible sshpass

# Some other utils
sudo apt install -y cmake valac libgtk-3-dev libkeybinder-3.0-dev libxml2-utils gettext txt2man

# Install spotify
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410
echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt update
sudo apt install spotify-client

#sudo ($echo "deb http://download.virtualbox.org/virtualbox/debian stretch contrib") >> /etc/apt/sources.list.d
#sudo apt-key add oracle_vbox_2016.asc
#sudo apt-get update
#sudo apt-get install virtualbox-5.1
#sudo apt-get install vagrant
# sudo apt-get install lib32ncurses5
# sudo apt install -y nodejs

# Install ranger and utils for it
sudo apt install ranger caca-utils highlight atool w3m w3m-img poppler-utils mediainfo

# Install yank
sudo apt install yank

# Install neofetch
sudo apt install neofetch

# Install urxvt with 256 colors 
sudo apt install rxvt-unicode-256color 

# Install tmux
sudo apt install tmux
