#!/bin/sh

_passwd=`getent passwd $GUEST_USER`
if [ "$_passwd" != "" ]; then
    GUEST_UID=`echo $_passwd | cut -d: -f 3`
    GUEST_GID=`echo $_passwd | cut -d: -f4`
    GUEST_GROUP=`getent group $GUEST_GID | cut -d: -f 1`
    HOME=`echo $_passwd | cut -d: -f 6`
else
    _group=`getent group $GUEST_GROUP`
    if [ "$_group" != "" ]; then
        GUEST_GID=`echo $_group | cut -d: -f 3`
    else
        groupadd -g $GUEST_GID $GUEST_GROUP
    fi
    HOME=${GUEST_HOME:-/home/$GUEST_USER}
    useradd -u $GUEST_UID -g $GUEST_GID -d $HOME -om -s /bin/bash $GUEST_USER
    mkdir -m 700 -p /var/run/user/$GUEST_UID
    chown $GUEST_UID:$GUEST_GID $HOME /var/run/user/$GUEST_UID
    for _skel in /etc/skel/.*; do
        _file=`basename $_skel`
        [ "$_file" != . -a "$_file" != .. ] && /usr/sbin/gosu $GUEST_USER cp -p /etc/skel/$_file $HOME
    done
fi

service ssh start
/usr/sbin/x2golistsessions_root

/docker/preexecAsRoot
exec /usr/sbin/gosu $GUEST_USER /docker/init.sh "$@"
