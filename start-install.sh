#!/bin/bash
echo "Starting installing"
apt-get install sudo
echo "sudo installed"
apt-get install nano
echo "nano installed"
apt-get install whois
echo "whois installed"
apt-get install openvpn
echo "openvpn installed"
apt-get install libpam-pwdfile
echo "libpam-pwdfile installed"
apt-get install dante-server
echo "dante-server installed"
apt-get install apache2 mysql-server php php-mysql libapache2-mpm-itk
echo "" > /etc/apache2/ports.conf
rm -R /etc/apache2/sites-*/*
echo "lamp installed"
service apache2 stop
echo "apache pre configured and stoped"

apt-get install nginx
rm -R /etc/nginx/sites-*/*
echo "nginx installed"

service nginx stop
echo "nginx stoped"
echo "Start dante-server configuration"

#dante-server conf
echo "Введите ip"
read ip
dante="logoutput: /var/log/danted.log\n
internal: ${ip} port = 1080\n
external: ${ip}\n
\n
socksmethod: pam.username\n
#socksmethod: none\n
clientmethod: none\n
user.privileged: root\n
user.unprivileged: nobody\n
user.libwrap: nobody\n
\n
client pass {\n
        from: 0.0.0.0/0 to: 0.0.0.0/0\n
        log: error connect disconnect\n
}\n
client block {\n
        from: 0.0.0.0/0 to: 0.0.0.0/0\n
        log: connect error\n
}\n
socks pass {\n
        from: 0.0.0.0/0 to: 0.0.0.0/0\n
        protocol: tcp udp\n
        command: bind connect\n
        log: error connect disconnect\n
}\n
socks block {\n
        from: 0.0.0.0/0 to: 0.0.0.0/0\n
        log: connect error\n
}"

pam_pass_conf="auth required pam_pwdfile.so pwdfile /etc/danted.sockd.passwd\n
account required pam_permit.so"
#dante
touch /etc/pam.d/sockd

# open file stream pam_pass_conf conf
exec 6>&1
# open file for writing
exec 1>/etc/pam.d/sockd
# write pam_pass_conf data
echo -e $pam_pass_conf
# close file
exec 1>&-
# close file stream
exec 1>&6
# close FD6
exec 6>&-
echo "Start dante-server user config generated"
#dante
touch /etc/danted.conf

# open file stream dante conf
exec 6>&1
# open file for writing
exec 1>/etc/danted.conf
# write dante data
echo -e $dante
# close file
exec 1>&-
# close file stream
exec 1>&6
# close FD6
exec 6>&-
echo "Start dante-server config generated"
#danted users
echo "Введите имя пользователя dante-server"
read dante_user
echo "Введите имя пользователя dante-server"
read dante_pass
danted_md5_pass=$(mkpasswd --method=md5 $dante_pass)
dant_first_user="${dante_user}:${danted_md5_pass}"
#dante
touch /etc/danted.sockd.passwd

# open file stream pam_pass_conf conf
exec 6>&1
# open file for writing
exec 1>/etc/danted.sockd.passwd
# write pam_pass_conf data
echo -e $dant_first_user
# close file
exec 1>&-
# close file stream
exec 1>&6
# close FD6
exec 6>&-
service danted start
echo "Dante-server configured and started"

#openvpn
openvpn="client-to-client\n
port 1194\n
proto tcp\n
dev tun\n
ca /etc/openvpn/ca/ca.crt\n
cert /etc/openvpn/keys/server.crt\n
key /etc/openvpn/keys/server.key\n
dh /etc/openvpn/dh/dh2048.pem\n
tls-server\n
tls-auth /etc/openvpn/ta/ta.key\n
auth SHA512\n
\n
server 10.8.0.0 255.255.255.0\n
ifconfig-pool-persist ipp.txt\n
keepalive 10 120\n
#persist-key\n
#persist-tun\n
status openvpn-status.log\n
log /var/log/openvpn.log\n
verb 3"

source /etc/openvpn/easy-rsa/clean-all
source /etc/openvpn/easy-rsa/vars
#ca
sh /etc/openvpn/easy-rsa/build-ca
mkdir /etc/openvpn/ca/
cp /etc/openvpn/easy-rsa/keys/ca* /etc/openvpn/ca/
#server keys
sh /etc/openvpn/easy-rsa/build-key-server server
mkdir /etc/openvpn/keys/
cp /etc/openvpn/easy-rsa/keys/server.* /etc/openvpn/keys/
#DH file
sh /etc/openvpn/easy-rsa/build-dh
mkdir /etc/openvpn/dh/
cp /etc/openvpn/easy-rsa/keys/dh* /etc/openvpn/dh/
#ta file
mkdir /etc/openvpn/ta/
openvpn --genkey --secret /etc/openvpn/ta/ta.key

#openvpn conf
touch /etc/openvpn/server.conf
exec 6>&1
# open file for writing
exec 1>/etc/openvpn/server.conf
# write pam_pass_conf data
echo -e $openvpn
# close file
exec 1>&-
# close file stream
exec 1>&6
# close FD6
exec 6>&-
openvpn /etc/openvpn/server.conf
echo "Openvpn configured and started"

echo "Setting iptables rules"

#dante iptables
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

iptables -A INPUT -i $ip -p tcp -m tcp --dport 1080 -j ACCEPT
iptables -A OUTPUT -o $ip -p tcp -m tcp --dport 1080 -j ACCEPT
iptables -A FORWARD -i $ip -p tcp -m tcp --dport 1080 -j ACCEPT
iptables -A FORWARD -o $ip -p tcp -m tcp --dport 1080 -j ACCEPT
