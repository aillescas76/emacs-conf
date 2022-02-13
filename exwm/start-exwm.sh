#!/bin/sh

# exec dbus-launch --exit-with-session emacs -mm --debug-init
start_daemons () {
    eval "$(gnome-keyring-daemon --start --components=ssh,secrets,pkcs11)"
    export SSH_AUTH_SOCK
    export GNOME_KEYRING_CONTROL
}

exwm () {
    export EXWM=1
    # Disable access control for the current user.
    xhost "+SI:localuser:$USER"

    # Make Java applications aware this is a non-reparenting window manager.
    export _JAVA_AWT_WM_NONREPARENTING=1

    # Set default cursor.
    # xsetroot -cursor_name left_ptr

    # Set keyboard repeat rate.
    # xset r rate 200 60

    # Finally start Emacs
    exec dbus-launch --exit-with-session emacs -mm --debug-init

}

start_daemons
exwm
