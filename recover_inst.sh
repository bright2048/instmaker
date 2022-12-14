#!/bin/sh
SCRIPTNAME=/etc/init.d/recover_inst.sh
do_start(){
    while read name 
    do
    docker start $name
    docker exec --user root $name bash -c " service ssh start"
    docker exec --user root $name bash -c "cd /etc/vncc/; nohup  ./vncc -c vncc.conf 1>/dev/null 2>&1 &"
    done</root/names.txt
}
do_stop(){
    while read name 
    do
    docker stop $name
    done</root/names.txt
}
case "$1" in
  start)
do_start
;;
  stop)
  do_stop
  ;;
  restart|force-reload|status)
;;
  *)
echo "Usage: $SCRIPTNAME start" >&2
exit 3
;;
esac
