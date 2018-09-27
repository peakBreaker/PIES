# Run startup script, first fix display
echo "Running startup script"
# Uncomment to rotate display left 
#xrandr --output DVI-D-1 --right-of DVI-I-1 --auto --rotate left


# Start some programs

dropbox start &
ulauncher --hide-window &
xscreensaver 
