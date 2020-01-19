#!/bin/bash

apt-get update -y
apt-get full-upgrade -y
apt-get install -y git curl wget zip

apt -y install lsb-release apt-transport-https ca-certificates 
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/php7.3.list
apt-get update -y
apt -y install php7.3
apt install -y php7.3-cli php7.3-fpm php7.3-json php7.3-pdo php7.3-mysql php7.3-zip php7.3-gd  php7.3-mbstring php7.3-curl php7.3-xml php7.3-bcmath php7.3-json
apt-get install php7.3-xml php7.3-mbstring php7.3-json php7.3-ctype php7.3-bcmath libssh2-1 php7.3-ssh2 -y
apt install libapache2-mod-php7.3 -y
clear

echo "Setting up apache"
sleep 1
sed -i 's@Listen[[:space:]]80@Listen 80\nListen 85@g' /etc/apache2/ports.conf
cat > /etc/apache2/sites-available/phpmyadmin.conf <<-END
<VirtualHost *:85>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/phpmyadmin
        ErrorLog /var/log/apache2/phpmyadmin.log
        CustomLog /var/log/apache2/phpmyadmin.log combined
</VirtualHost>
END
rm /etc/apache2/sites-available/000-default.conf
cat > /etc/apache2/sites-available/000-default.conf <<-END
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/dnsmanager/public
        <Directory /var/www/dnsmanager/public/>
                Options Indexes FollowSymLinks
                AllowOverride All
                Require all granted
        </Directory>
        ErrorLog /var/log/apache2/dnsmanager.log
        CustomLog /var/log/apache2/dnsmanager.log combined
</VirtualHost>
END
a2enmod rewrite
a2enmod headers
cd /etc/apache2/sites-available
a2ensite phpmyadmin.conf
service apache2 restart
echo "Setting up MySQL Server"
sleep 2
apt-get install mariadb-server -y
read -p "Enter Database Username: " dbuname
read -p "Enter Database Password: " dbpword
QUERY1="create user '$dbuname'@'%' identified by '$dbpword';"
QUERY2="grant all privileges on *.* to '$dbpword'@'%';"
QUERY3="flush privileges;"
mysql -e "$QUERY1"
mysql -e "$QUERY2"
mysql -e "$QUERY3"
wget -O phpmyadmin.zip https://files.phpmyadmin.net/phpMyAdmin/4.9.1/phpMyAdmin-4.9.1-all-languages.zip
unzip phpmyadmin.zip -d /var/www/
PHPMYADMIN=$(unzip -qql phpmyadmin.zip | sed -r '1 {s/([ ]+[^ ]+){3}\s+//;q}')
mv /var/www/$PHPMYADMIN /var/www/phpmyadmin
QUERY4="create database dnsmanager;"
mysql -e "$QUERY4"


wget -qO dnsmanager.zip https://dropmb.com/files/8d6e1e898bd573dcd5ad41fef9c31401.zip
unzip dnsmanager.zip -d /var/www/
chown -R www-data:www-data /var/www/dnsmanager
chmod -R 755 /var/www/dnsmanager
cd /var/www/dnsmanager/ 
php artisan migrate
cd
rm -r /root/*
