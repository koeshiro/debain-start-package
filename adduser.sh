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
chown -R $username:$username /home/$username/data/
chmod -R 755 /home/$username/data
chown root:$username /home/$username
adduser $username www-data
echo -e "Username is $username\nPassword is $password"