#!/bin/sh
X2GO_PORT=`echo $DISPLAY | cut - -d: -f 2`
SESSION_NAME=user-00-0000000000_stR_dp32
X2GO_COOKIE=`mcookie`
GR_PORT=10000
SOUND_PORT=10001
FS_PORT=10002

NX_ROOT=$HOME/.x2go
X2GO_SESSION_ROOT=$NX_ROOT/C-$SESSION_NAME
X_AUTHORITY=$HOME/.Xauthority

for line in `/usr/bin/x2golistsessions`; do
    echo $line
    session=`echo $line | cut - -d'|' -f 2`
    echo $session
    if [ "$session" = $SESSION_NAME ]; then
        hasSession=1
    fi
done

if [ -z "$hasSession" ]; then
    /usr/lib/x2go/x2goinsertsession $X2GO_PORT $HOSTNAME $SESSION_NAME > /dev/null
    /usr/lib/x2go/x2goinsertport $HOSTNAME $SESSION_NAME $GR_PORT > /dev/null
    /usr/lib/x2go/x2goinsertport $HOSTNAME $SESSION_NAME $SOUND_PORT > /dev/null
    /usr/lib/x2go/x2goinsertport $HOSTNAME $SESSION_NAME $FS_PORT > /dev/null
fi

rm -f /tmp/.X$X2GO_PORT-lock
mkdir -p $X2GO_SESSION_ROOT/keyboard

/usr/bin/x2goserver-run-extensions $SESSION_NAME pre-start

/usr/bin/xauth -f $X_AUTHORITY add $HOSTNAME/unix:$X2GO_PORT MIT-MAGIC-COOKIE-1 $X2GO_COOKIE
/usr/bin/xauth -f $X_AUTHORITY add $HOSTNAME:$X2GO_PORT MIT-MAGIC-COOKIE-1 $X2GO_COOKIE

echo nx/nx,link=adsl,pack=16m-jpeg-9,limit=0,root=$X2GO_SESSION_ROOT,cache=8M,images=32M,type=unix-kde-depth_32,id=$SESSION_NAME,cookie=$X2GO_COOKIE,errors=$X2GO_SESSION_ROOT/session.log,kbtype=null/null,resize=1,fullscreen=0,accept=localhost,listen=$GR_PORT,clipboard=both,client=linux,menu=0,state=$X2GO_SESSION_ROOT/state:$X2GO_PORT > $X2GO_SESSION_ROOT/options

NX_TEMP=/tmp NX_ROOT=$NX_ROOT DISPLAY=nx/nx,options=$X2GO_SESSION_ROOT/options:$X2GO_PORT /usr/bin/x2goagent -extension XFIXES -nolisten tcp -dpi $X2GO_DPI -R -norootlessexit -auth $X_AUTHORITY :$X2GO_PORT &
X2GO_AGENT_PID=$!

/usr/bin/x2goserver-run-extensions $SESSION_NAME post-start
/usr/lib/x2go/x2gocreatesession $X2GO_COOKIE $X2GO_AGENT_PID 127.0.0.1 $GR_PORT $SOUND_PORT $FS_PORT $SESSION_NAME


PSEUDO_PORT=2

mkdir -p $NX_ROOT/S-$X2GO_PORT
/docker/pseudo_x11.py $PSEUDO_PORT > $NX_ROOT/S-$X2GO_PORT/pseudo_x11.log &
DISPLAY=:$PSEUDO_PORT /usr/bin/nxproxy -S nx/nx,root=$NX_ROOT,connect=localhost,cookie=$X2GO_COOKIE,port=$GR_PORT,errors=$NX_ROOT/S-$X2GO_PORT/session.log:$X2GO_PORT > $NX_ROOT/S-$X2GO_PORT/session.log 2> $NX_ROOT/S-$X2GO_PORT/session.log

sleep 1

"$@" &
CMD_PID=$!
trap "kill -TERM $CMD_PID; wait $CMD_PID" TERM; wait $CMD_PID

/usr/bin/x2goterminate-session $SESSION_NAME
sleep 2
