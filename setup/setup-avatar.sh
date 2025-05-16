#!/bin/bash

# Script cài đặt server Ubuntu với Java 11, MariaDB, phpMyAdmin, Maven và PM2
# Mở port 19128 và 3306

# Kiểm tra quyền root
if [ "$(id -u)" != "0" ]; then
   echo "Script này yêu cầu quyền root để chạy" 1>&2
   echo "Vui lòng chạy với sudo" 1>&2
   exit 1
fi

# Cập nhật hệ thống
echo "===== Cập nhật hệ thống ====="
apt-get update
apt-get upgrade -y

# Cài đặt Java 11
echo "===== Cài đặt Java 11 ====="
apt-get install -y openjdk-11-jdk
java -version

# Cài đặt MariaDB
echo "===== Cài đặt MariaDB ====="
apt-get install -y mariadb-server

# Bảo mật MariaDB
echo "===== Cấu hình bảo mật MariaDB ====="
mysql_secure_installation

# Cài đặt Apache
echo "===== Cài đặt Apache2 ====="
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2

# Cài đặt PHP và các extension cần thiết
echo "===== Cài đặt PHP và các extension ====="
apt-get install -y php php-mysql php-mbstring php-zip php-gd php-json php-curl

# Cài đặt phpMyAdmin
echo "===== Cài đặt phpMyAdmin ====="
apt-get install -y phpmyadmin

# Cấu hình phpMyAdmin
echo "===== Cấu hình phpMyAdmin ====="
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Cấu hình tường lửa (UFW)
echo "===== Cấu hình tường lửa ====="
apt-get install -y ufw
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 19128/tcp
ufw allow 3306/tcp

# Kích hoạt tường lửa
echo "===== Kích hoạt tường lửa ====="
ufw --force enable

# Cài đặt Maven
echo "===== Cài đặt Maven ====="
apt-get install -y maven
mvn -version

# Tạo file cấu hình MariaDB để lắng nghe trên tất cả IP
echo "===== Cấu hình MariaDB để lắng nghe từ xa ====="
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
node -v
npm -v

# Cài đặt PM2
echo "===== Cài đặt PM2 ====="
npm install -g pm2
pm2 startup
pm2 save
cat > /etc/mysql/mariadb.conf.d/50-server.cnf << EOF
[server]
[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
socket                  = /run/mysqld/mysqld.sock
port                    = 3306
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
bind-address            = 0.0.0.0
query_cache_size        = 16M
log_error = /var/log/mysql/error.log
expire_logs_days        = 10
character-set-server    = utf8mb4
collation-server        = utf8mb4_general_ci

[embedded]

[mariadb]

[mariadb-10.3]
EOF

# Khởi động lại MariaDB để áp dụng cấu hình mới
systemctl restart mariadb

# Tạo người dùng MariaDB có thể truy cập từ xa
echo "===== Tạo người dùng MariaDB có thể truy cập từ xa ====="
read -p "Nhập tên người dùng MariaDB: " MYSQL_USER
read -sp "Nhập mật khẩu người dùng MariaDB: " MYSQL_PASSWORD
echo ""

mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo "===== Hoàn tất cài đặt ====="
echo "Java 11 đã được cài đặt"
echo "Maven đã được cài đặt"
echo "Node.js và PM2 đã được cài đặt"
echo "MariaDB đã được cài đặt và lắng nghe trên port 3306"
echo "phpMyAdmin đã được cài đặt tại http://[địa_chỉ_IP]/phpmyadmin"
echo "Tường lửa đã được cấu hình để cho phép các cổng 22, 80, 443, 19128, 3306"
echo "Người dùng MariaDB '${MYSQL_USER}' đã được tạo và có thể truy cập từ xa"

# Hiển thị thông tin IP
echo "===== Địa chỉ IP của server ====="
hostname -I