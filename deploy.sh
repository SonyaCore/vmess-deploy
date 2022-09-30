#!/bin/bash

# Vmess Deploy
# --------------------------------
# author    : SonyaCore
#	      https://github.com/SonyaCore
#

PORT=80
UUID=$(cat /proc/sys/kernel/random/uuid)
IP=$(hostname -I | cut -d' ' -f1)
CONFIGNAME="config.json"
CONFIGLOGLEVEL = 'info'
WEBSOCKETPATH = '/graphql'
DOCKERCOMPOSEVERSION = '2.11.1'
LINKNAME = 'v2ray'

permissioncheck(){
ROOT_UID=0
if [[ $UID == $ROOT_UID ]]; then true ; else echo -e "You Must be the ROOT to Perfom this Task" ; exit 1 ; fi
}

# Permission Check
permissioncheck

echo "Run this script on external IP"
echo "Press Ctrl + C if you want to cancel the installation"

sleep 5

config(){
cat > docker-compose.yaml <<DOCKER
version: '3'
services:
  v2ray:
    image: v2fly/v2fly-core
    restart: always
    network_mode: host
    environment:
      - V2RAY_VMESS_AEAD_FORCED=false
    volumes:
        - ./$CONFIGNAME:/etc/v2ray/config.json:ro
DOCKER

cat > $CONFIGNAME <<CONFIG
{
  "log": {
    "loglevel": "$CONFIGLOGLEVEL"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vmess",
      "allocate": {
        "strategy": "always"
      },
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 1,
            "alterId": 0,
            "email": "client@example.com"
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "connectionReuse": true,
          "path": "$WEBSOCKETPATH"
        },
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"
                ],
                "Transfer-Encoding": ["chunked"],
                "Connection": ["keep-alive"],
                "Pragma": "no-cache"
              }
            }
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
} 
CONFIG
}

# Update Repo & Install Docker If Docker not exists in system.

if [[ -f '/usr/bin/docker' ]] || [[ -f '/usr/local/bin/docker' ]]
then
    true
else
    curl https://get.docker.com | sudo sh
fi

if [[ -f '/usr/bin/docker-compose' ]] || [[ -f '/usr/local/bin/docker-compose' ]]
then
    true
else
    curl -SL https://github.com/docker/compose/releases/download/v$DOCKERCOMPOSEVERSION/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

STATUS="$(systemctl is-active docker.service)"

if [ "${STATUS}" = "active" ]; then
    echo "Docker service are already enabled."
else 
    systemctl enable --now containerd
    systemctl enable --now docker
fi

sleep 3

# makeconfig
config

# Allow firewall 
firewall(){
  # Check if UFW Exist
  if [ -f "/usr/sbin/ufw" ]; then ufw allow $PORT/tcp ; ufw allow $PORT/udp; ufw reload; fi
  # Allow PORT in IP Tables
  iptables -t filter -A INPUT -p tcp --dport $PORT -j ACCEPT
  iptables -t filter -A OUTPUT -p tcp --dport $PORT -j ACCEPT
}
firewall

# Start Docker Compose Service
sudo docker-compose up -d || printf "Pulling Failed \nMake sure your IP has access to the docker registry."

sleep 2

echo "! UUID : $UUID"
echo "! Use Below Link for Import:"
echo ""

# Vmess Link Generation
printf vmess://;echo \{\"add\":\"$IP\", \
\"aid\":\"0\", \
\"host\":\"\", \
\"id\":\"$UUID\", \
\"net\":\"ws\", \
\"path\":\"$WEBSOCKETPATH\", \
\"port\":\"$PORT\", \
\"ps\":\"$LINKNAME\", \
\"tls\":\"\", \
\"type\":\"none\", \
\"v\":\"2\"\}|base64 -w0;echo

echo ""
echo "! After importing vmess link change the IP to your Internal Server IP"

# Clean Up
rm -rf deploy.sh
