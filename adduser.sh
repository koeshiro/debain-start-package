#!/bin/bash
echo "Введите имя пользователя"
read username
echo "Введите пароль"
read password
#pass=$(head -c 100 /dev/urandom | base64 | sed 's/[+=/A-Z]//g' | tail -c 15)
mkdir /home/$username
chown -R root /home/$username
chmod -R 755 /home/$username
#useradd -p$password $username
useradd -d /home/$username/data -m $username -s /bin/bash
pass="${username}:${password}"
echo $pass
echo $pass | chpasswd
#echo -e "${password}\n${password}\n" | passwd $username
mkdir /home/$username/data/html
mkdir /home/$username/data/logs
mkdir /home/$username/data/tmp
mkdir /home/$username/data/openvpn
chown -R $username:$username /home/$username/data/
chmod -R 755 /home/$username/data
chown root:$username /home/$username
adduser $username www-data
echo -e "Username is $username\nPassword is $password"

#Openvpn
echo "Введите ip сервера"
read $ip
ca=$(cat /etc/openvpn/ca/ca.crt)
ta=$(cat /etc/openvpn/ta/ta.key)
source /etc/openvpn/easy-rsa/clean-all
source /etc/openvpn/easy-rsa/vars
cp /etc/openvpn/ca/
sh /etc/openvpn/easy-rsa/build-key-pass $username

caUser=$(cat /etc/openvpn/easy-rsa/keys/$username.crt)
key=$(cat /etc/openvpn/easy-rsa/keys/$username.key)
openvpn="client\n
dev tun\n
proto tcp\n
remote ${ip} 1194\n
#resolv-retry infinite\n
#ca ca.crt\n
<ca>${ca}</ca>\n
#cert koeshiro.crt\n
<cert>${caUser}</cert>\n
#key koeshiro.key\n
<key>${key}</key>\n
#tls-auth ta.key 1\n
<tls-auth>${ta}</tls-auth>\n
auth SHA512\n
verb 3"
