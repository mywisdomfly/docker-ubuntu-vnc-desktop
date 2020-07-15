#!/bin/bash

mkdir -p /var/run/sshd

chown -R root:root /root
mkdir -p /root/.config/pcmanfm/LXDE/
cp /usr/share/doro-lxde-wallpapers/desktop-items-0.conf /root/.config/pcmanfm/LXDE/

# if [ -n "$VNC_PASSWORD" ]; then
#     echo -n "$VNC_PASSWORD" > /.password1
#     x11vnc -storepasswd $(cat /.password1) /.password2
#     chmod 400 /.password*
#     sed -i 's/^command=x11vnc.*/& -rfbauth \/.password2/' /etc/supervisor/conf.d/supervisord.conf
#     export VNC_PASSWORD=
# fi

x11vnc -storepasswd $VNC_PASSWD /etc/x11vnc.pass
# Find usable display port
DISPLAY_NUM=0
unset TEST_HAS_RUN
until [ $TEST_HAS_RUN ] || (( $DISPLAY_NUM > 30 ))
do
 Xvfb :$DISPLAY_NUM &
 jobs
 sleep 3  # assumption here is that Xvfb will exit quickly if it can't launch
 if jobs | grep Xvfb
 then  
   echo "launching test on :$DISPLAY_NUM"
    TEST_HAS_RUN=1
    pkill Xvfb*
 else   
   let DISPLAY_NUM=$DISPLAY_NUM+1
 fi
done


echo "export DISPLAY=:${DISPLAY_NUM}" >> ~/.bashrc
# export DISPLAY=":$DISPLAY_NUM"
# 设定端口号
if [ -n "$PAI_CONTAINER_HOST_vnc_PORT_LIST" ]; then
    sed -i "s/9018/$PAI_CONTAINER_HOST_vnc_PORT_LIST/" /etc/supervisor/conf.d/supervisord.conf
fi

sed -i "s/:1/:${DISPLAY_NUM}/" /etc/supervisor/conf.d/supervisord.conf

# /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

noVNC/utils/launch.sh --listen $PAI_CONTAINER_HOST_vnc_http_PORT_LIST --vnc localhost:$PAI_CONTAINER_HOST_vnc_PORT_LIST  >> vnc.log &

# cd /usr/lib/web && ./run.py > /var/log/web.log 2>&1 &
# nginx -c /etc/nginx/nginx.conf
exec /bin/tini -- /usr/bin/supervisord -n
