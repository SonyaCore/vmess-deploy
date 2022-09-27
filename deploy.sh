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
    "loglevel": "info"
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
          "path": "/graphql"
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

# Update Repo & Install Docker &
curl https://get.docker.com | sudo sh
curl -SL https://github.com/docker/compose/releases/download/v2.11.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


# Run Service
systemctl enable --now containerd
systemctl enable --now docker


sleep 3

# Make Config
config

# Allow firewall 
ufw allow $PORT

# Start Docker Compose Service
docker-compose up -d || printf "Pulling Failed \nMake sure your IP has access to the docker registry."

echo "! UUID : $UUID"
echo "! Use Below Link for Import:"
echo ""

# Vmess Link Generation
printf vmess://;echo \{\"add\":\"$IP\", \
\"aid\":\"0\", \
\"host\":\"\", \
\"id\":\"$UUID\", \
\"net\":\"ws\", \
\"path\":\"/graphql\", \
\"port\":\"$PORT\", \
\"ps\":\"v2ray\", \
\"tls\":\"\", \
\"type\":\"none\", \
\"v\":\"2\"\}|base64 -w0;echo

echo ""
echo "! After importing vmess link change the IP to your Internal Server IP"

# Clean Up
rm -rf deploy.sh