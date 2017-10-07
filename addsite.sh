#!/bin/bash
echo "Введите имя сайта"
read sitename
echo "Введите порт"
read siteport
echo "Введите имя пользователя"
read username 
#Nginx settings
mkdir /home/$username/data/html/$sitename
chmod 755 -R /home/$username/data/html/$sitename
chown $username:$username /home/$username/data/html/$sitename
mkdir /home/$username/data/logs/$sitename/
nginx="
server {\n
	listen *:80;\n
	server_name ${sitename};\n
	access_log /home/${username}/data/logs/${sitename}/nginx_access_${sitename}.log;\n
	error_log /home/${username}/data/logs/${sitename}/nginx_error_${sitename}.log;\n
	client_max_body_size 500m;\n
	\n
	location / {\n
		proxy_pass http://127.0.0.1:${siteport}/;\n
		proxy_set_header Host \$host:80;\n
		proxy_set_header X-Real-IP \$remote_addr;\n
		proxy_set_header X-Forwarded-For \$remote_addr;\n
		proxy_connect_timeout 120;\n
		proxy_send_timeout 120;\n
		proxy_read_timeout 180;\n
	}\n
	\n
	location ~* \.(jpg|jpeg|png|gif|css|js|zip|rar|docx|doc|bmp|txt)$ {\n
		root /home/${username}/data/html/${sitename};\n
		index  index.php;\n
	}\n
	location @fallback {\n
		proxy_pass http://127.0.0.1:${siteport};\n
		proxy_set_header Host \$host;\n
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n
		proxy_set_header X-Real-IP \$remote_addr;\n
	}\n
}
"
apache="
<VirtualHost 127.0.0.1:${siteport}>\n
        ServerAdmin webmaster@localhost\n
        DocumentRoot /home/${username}/data/html/${sitename}\n
\n
        ErrorLog /home/${username}/data/logs/${sitename}/apache_error_${sitename}.log\n
        CustomLog /home/${username}/data/logs/${sitename}/apache_access_${sitename}.log combined\n
		\n
		<Directory /home/${username}/data/html/${sitename}>\n
				Options Indexes FollowSymLinks\n
				AllowOverride all\n
				Require all granted\n
		</Directory>\n
		\n
		<IfModule mpm_itk_module>\n
			AssignUserId ${username} ${username}\n
		</IfModule>\n
		\n
</VirtualHost>\n
"

#nginx
touch /etc/nginx/sites-available/$sitename.conf

# open file stream nginx conf
exec 6>&1
# open file for writing
exec 1>/etc/nginx/sites-available/$sitename.conf
# write nginx data
echo -e $nginx
# close file 
exec 1>&-
# close file stream
exec 1>&6
# close FD6
exec 6>&-
cp /etc/nginx/sites-available/$sitename.conf /etc/nginx/sites-enabled

#apache2
touch /etc/apache2/sites-available/$sitename.conf

# open file stream apache2 conf
exec 6>&1
# open file for writing
exec 1>/etc/apache2/sites-available/$sitename.conf
# write apache2 data
echo -e $apache
# close file 
exec 1>&-
# close file stream
exec 1>&6
# close FD6
exec 6>&-
cp /etc/apache2/sites-available/$sitename.conf /etc/apache2/sites-enabled

echo "NameVirtualHost *:${siteport}" >> /etc/apache2/ports.conf
echo "Listen ${siteport}" >> /etc/apache2/ports.conf