CREATE DATABASE metastore;

CREATE USER 'hiveuser'@'localhost' IDENTIFIED BY 'con2day';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'hiveuser'@'localhost';
GRANT ALL PRIVILEGES on metastore.* TO 'hiveuser'@'localhost';

CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'con2day';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'hiveuser'@'%';
GRANT ALL PRIVILEGES on metastore.* TO 'hiveuser'@'%';

FLUSH PRIVILEGES;
