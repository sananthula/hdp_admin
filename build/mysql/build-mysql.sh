#!/bin/bash
# Hortonworks University
# This script is for training purposes only and is to be used only
# in support of approved Hortonworks University exercises. Hortonworks
# assumes no liability for use outside of our traning environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Name: buildMySQL.sh
# Author: WKD 
# Date: 4 Sept 2014
# Purpose: Build script for a mysql database built on a CentOS 6 
# operating system.
# You must copy the rpm for MySQL and the JDBC into /tmp
# Use the alternative script for building on CentOS 7.
# There is an alternative script for pulling the package using curl.

# VARIABLES
myhost="$(hostname) "
mysqltar=MySQL-5.6.25-1.el6.x86_64.rpm-bundle.tar
jdbcver=mysql-connector-java-5.1.36
jdbctar=${jdbcver}.tar.gz

# FUNCTIONS
function testing() {
if [ "$(id -u)" != "0" ]; then
        echo "ERROR: This script must be run using sudo" 1>&2
        exit 1
fi

if [ ! -f $jdbctar ]; then
	echo "ERROR: You must have the rpm files for the JDBC in /tmp."
	exit 1
fi
}

function installMysql() {
# It is important you must ensure we do not have a conflict
# in lib files.
	read -p "Will this be a local install? (Y/N) " answer
	if [[ $answer == "Y" || $answer == "y" ]]; then

		if [ ! -f $mysqltar ]; then
			echo "ERROR: You must have the rpm files for MySQL. "
			exit 1
		fi
		yum remove -y mysql-libs
		tar xvf $mysqltar 
		yum -y localinstall MySQL-server-*.el6.x86_64.rpm
		yum -y localinstall MySQL-client-*.el6.x86_64.rpm
		yum -y localinstall MySQL-devel-*.el6.x86_64.rpm
	else
		yum -y install mysql-server
	fi
}

function setupDB() {
# This runs the install scripts for MySQL.
# The default is for MySQL to start during bootup. The chkconfig command
# line is to ensure known state, not really required.
	mysql_install_db --user=mysql
	service mysql start
	mysql_secure_installation
	chkconfig mysql on
}

function installJDBC() {
# Install for the jdbc. Also add in the links to Sqoop and Hive Metastore
	tar xvf $jdbctar 
	mkdir /usr/share/java
	cd $jdbcver
	cp $jdbcver-bin.jar /usr/share/java
	cd /usr/share/java
	ln -s $jdbcver-bin.jar mysql-connector-java.jar 
}

function cleanUP() {
	rm MySQL*tar
	rm MySQL*rpm
	rm mysql-connector*tar.gz
	rm mysql-connector*
}

function postInstructions() {
	echo
	echo "***POST BUILD INSTRUCTIONS"
	echo
	echo "1. Validate by login as root to mysql." 
}

# MAIN
testing
installMysql
setupDB
installJDBC
cleanUP

echo
echo "***"$myhost "completed " $0
postInstructions
