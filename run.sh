#!/bin/bash
DEPLOY="deploy.sh"

help(){
    echo "vmess deploy script"
    echo "e.x : ./run --ip 127.0.0.1 --user root --port 22 --install"
    echo ""
    echo "-h  | --help       show help and exit"
    echo "-ip |              set ip for ssh"
    echo "-u  | --user       set user for ssh"
    echo "-p  | --port       set port for ssh"
    echo "-i  | --install    deploy vmess to server"
}

install(){
scp -P $PORT $DEPLOY $USER@$IP:~
ssh $USER@$IP -p $PORT <<'RUN'
       chmod +x deploy.sh
       sudo ./deploy.sh
RUN
}

while (( $# )); do
   case $1 in
      -h | --help) help ; exit 1 ;;
      -ip| --ip)   IP=$2 ;;
      -u | --user) USER=$2 ;;
      -p | --port) PORT=$2 ;;
      -i | --install) install ; exit 1 ;;
      -*) echo "Error: Invalid option" >&2; exit 1 ;;
   esac
   shift
done

set -- "${args[@]}"