<h2 align="center"> vmess-deploy </h2>
vmess-deploy are for quickly set up your desired v2ray VPN server

How to Use : 

**Git clone :**
```bash
https://github.com/SonyaCore/vmess-deploy.git
```
**Give executable permission to run.sh file**
```
chmod +x run.sh
```
**Then you can give your server details to the script to install:**
```
./run.sh —user root —ip External-IP —port 22 —install
```
Note:
I used a ready-made template for its configuration here
You can change the protocol or... according to your needs and then do the installation

**After installation, it will give you a link that you can use it to import on your client**
 
And if you want to use the internal IP to bypass the filter:

```
./run.sh —user root —ip Exernal-IP -fi HOST-IP -fu HOST-USER --forward
```
Manual :
```
ssh to internal ip
sudo screen ssh -o GatewayPorts=true -N -L 80:0.0.0.0:80 USER@External-IP
```
And then change the IP in your client to your internal IP so that you can connect to your external server through it.

And in this way, a bridge is created between the internal and external server, so that when you do not have access to the Internet, or rather (the free world), you connect through the IP that has access, and that IP also routes your traffic to your external server.

 
Note:
 You can also write a service for this so that when the server is restarted, forwarding is done again
