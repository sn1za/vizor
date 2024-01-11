#!/bin/bash


apt-get update 
apt-get install curl


#Telegram creds
TELEGRAM_BOT_TOKEN="6453701849:AAG0M_375V4cEIzU8vUmGiNS4yY7HfjFY3k"
TELEGRAM_CHAT_ID="-4098948141"


send_telegram_notification() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d "chat_id=$TELEGRAM_CHAT_ID" \
       -d "text=$message"
}



#trap 'send_telegram_notification "Скрипт был прерван."; exit 1' SIGINT SIGTERM


cd /tmp/
git clone git@github.com:sn1za/vizor.git
cd vizor/

if command -v nginx &> /dev/null; then
    echo "nginx уже установлен."
else
    echo "nginx не установлен."
    apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    apt update && apt install nginx -y


    cp files/nginx/nginx.conf /etc/nginx/
    cp files/nginx/domain.conf /etc/nginx/conf.d/
    systemctl enable --now nginx
fi

if command -v apache2 &> /dev/null; then
    echo "apache2 уже установлен."
else
	apt-get install -y apache2
	a2dissite 000-default
	rm /etc/apache2/sites-enabled/000-default.conf || echo ok
	cp files/apache/domain.conf  /etc/apache2/sites-enabled/domain.com.conf
	a2ensite domain.com
	sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf
	systemctl enable --now apache2
fi


if command -v php &> /dev/null; then
    echo "php уже установлен."
else
	apt install -y php libapache2-mod-php php-mysql
	cp files/apache/php.ini /etc/php/8.1/apache2/php.ini
fi

if command -v mysql &> /dev/null; then
    echo "mysql уже установлен."
else
	apt install -y mysql-server
	cp files/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
	systemctl restart mysql
	systemctl enable --now mysql
	mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
	mysql -e "CREATE DATABASE domain;"
	mysql -e "CREATE USER 'domainuser'@'localhost' IDENTIFIED BY 'mypassword';"
	mysql -e "GRANT ALL PRIVILEGES ON domain.* TO 'domainuser'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
fi

#WordPress
if [ -e /var/www/html/wp-config.php ]; then
	echo "Wordress уже установлен"
else
	wget https://wordpress.org/latest.tar.gz
	tar -zxvf latest.tar.gz
	mv wordpress/* /var/www/html/
	chown -R www-data:www-data /var/www/html/
	find /var/www/html/ -type d -exec chmod 0755 {} \;
	find /var/www/html/ -type f -exec chmod 0644 {} \;
	mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	sed -i 's/'database_name_here'/'domain'/g' /var/www/html/wp-config.php
	sed -i 's/'username_here'/'domainuser'/g' /var/www/html/wp-config.php
	sed -i 's/'password_here'/'mypassword'/g' /var/www/html/wp-config.php
fi



# Отправка уведомления в Telegram о завершении
send_telegram_notification "Скрипт развертывания завершен успешно."

