
## Generate ssh keys
ssh-keygen -t rsa -b 4096

## Dropbox install
mktemp dropbox_install_tmp.XXX
cd dropbox_install.*
git clone https://aur.archlinux.org/dropbox.git
cd dropbox
pacman -Syu
makepkg -s
pacman -U dropbox*.pkg.tar.xz
cd ../../ 
rm -rf dropbox_install_tmp.XXX

# add to groups
sudo usermod -a -G <groups> <user>
