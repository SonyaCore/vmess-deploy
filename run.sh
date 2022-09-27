#!/bin/bash

DEPLOY="deploy.sh"
PORT=22
FWPORT=22

########################## Text ############################
txtsource='enter source password : \n'
#txtdestination='enter destination password :\n'

help(){
    echo "vmess deploy script"
    echo "e.x : ./run --ip 127.0.0.1 --user root --port 22 --install"
    echo ""
    echo "Install Arguments :"
    echo "-h  | --help              show help and exit"
    echo "-ip | --ip                set ip for ssh"
    echo "-u  | --user              set user for ssh"
    echo "-p  | --port              set optional port for ssh"
    echo "-i  | --install           deploy vmess to server"
    echo "Forwarding Arguments :"
    echo "-fi | --forwarded-ip      set ip for forwarding host"
    echo "-fu | --forwarded-user    set user for forwarding host"
    echo "-fp | --forwarded-port    set optional port for forwarding host"
    echo "-f  | --forward forward   forward host to server"
}

install(){
scp -P $PORT $DEPLOY $USER@$IP:~
ssh $USER@$IP -p $PORT <<'RUN'
       chmod +x deploy.sh
       sudo ./deploy.sh
RUN
}

forward(){
   printf "\033[0;32mSSH Forwarding.\033[0m\n"
   printf "$txtsource"
   ssh $FWUSER@$FWIP -p $FWPORT -t "sudo screen \
   ssh \
   -o GatewayPorts=true \
   -o StrictHostKeyChecking=no \
   -o PreferredAuthentications=password -N -L 80:0.0.0.0:80 $USER@$IP"
}

while (( $# )); do
   case $1 in
      -h | --help) help ; exit 1 ;;

      # Install Argument
      -ip| --ip)   IP=$2 ;;
      -u | --user) USER=$2 ;;
      -p | --port) PORT=$2 ;;
      -i | --install) install ; exit 1 ;;

      # Forward Argument
      -fi | --forwarded-ip) FWIP=$2 ;;
      -fu | --forwarded-user) FWUSER=$2 ;;
      -fp | --forwarded-port) FWPORT=$2 ;;
      -f  | --forward) forward ; exit 1 ;;
      
      -*) echo "Error: Invalid option" >&2; exit 1 ;;
   esac
   shift
done

set -- "${args[@]}"