#!/bin/bash
apt-get install nano
apt-get install whois
apt-get install openvpn
apt-get install libpam-pwdfile
apt-get install dante-server
apt-get install apache2 mysql-server php php-mysql libapache2-mpm-itk 
apt-get install nginx
echo "" > /etc/apache2/ports.conf
#dante-server conf
echo "Введите ip"
read ip
dante="
logoutput: /var/log/danted.log\n
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
}
"
pam_pass_conf="
auth required pam_pwdfile.so pwdfile /etc/danted.sockd.passwd\n
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

#dante iptables
iptables -P INPUT ACCEPT
iptables -P OUTPUTE ACCEPT
iptables -P FORWARD ACCEPT

iptables -A INPUT -i $ip -p tcp -m tcp --dport 1080 -j ACCEPT
iptables -A OUTPUTE -i $ip -p tcp -m tcp --dport 1080 -j ACCEPT
iptables -A FORWARD -i $ip -p tcp -m tcp --dport 1080 -j ACCEPT