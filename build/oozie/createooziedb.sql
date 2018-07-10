CREATE DATABASE ooziedb;

CREATE USER 'oozieuser'@'localhost' IDENTIFIED BY 'con2day';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'oozieuser'@'localhost';
GRANT ALL PRIVILEGES ON ooziedb.* to 'oozieuser'@'localhost' IDENTIFIED BY 'con2day';

CREATE USER 'oozieuser'@'%' IDENTIFIED BY 'con2day';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'oozieuser'@'%';
GRANT ALL PRIVILEGES ON ooziedb.* to 'oozieuser'@'%' IDENTIFIED BY 'con2day';

FLUSH PRIVILEGES;
