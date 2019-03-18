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

# Name: build-admin-server.sh
# Author: WKD 
# Date: 180301
# Purpose: This is a build script to build out the admin01 server.
# You will have to edit some variables within the script before you
# run the script. Ensure you edit the Ambari version.
#

# CHANGES
# RFC-1274 Script Maintenance

# VARIABLES
NUMARGS=$#
ADMIN_HOST=$1
ETCDIR=${HOME}/etc
AMBARI_VER=2.5.1.0
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE=${LOGDIR}/build-admin-server-${DATETIME}.log

# FUNCTIONS
function usage() {
# usage()
        echo "Usage: sudo $(basename $0) [admin_hostname]"
        exit 1
}

function callFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/functions.sh ]; then
                source ${HOME}/sbin/functions.sh
        else
                echo "ERROR: The file ${HOME}/sbin/functions.sh not found."
                echo "This required file provides supporting functions."
        fi
}

function intro() {
# Post the follow on instructions, primarily testing the success
# of the build.
        echo
        echo "*** PRE BUILD INSTRUCTIONS"
	echo "1. Check the Ambari versions within this script."
	echo "2. Edit the IP address in the resolv.conf file found in ~/etc."
	echo "3. Edit the IP address in the zone file and reverse lookup file found in ~/etc."
	checkContinue
}

function configBind() {
# Config the local bind server, ensure you edited the resolv.conf 
	# Install bind
	echo
	echo "***Install bind"
	yum -y install bind bind-utils

	# Configure bind. These files must be edited before hand.
	echo
	echo "*** Config bind"
	cp -r ${ETCDIR}/named.conf /etc/named.conf
	chgrp -R named /etc/named.conf 

	mkdir -p /var/named/zones
	cp -r ${ETCDIR}/named/* /var/named/zones
	chgrp -R named /var/named/zones

	# This command moves the resolv.conf file 
	chattr -i /etc/resolv.conf
	cp -r ${ETCDIR}/resolv.conf /etc/resolv.conf

	# This command prevents the resolv.conf from being overwritten 
	# during boot up.
	chattr +i /etc/resolv.conf

	# restart the named
	systemctl stop named
	systemctl enable named
	systemctl start named
}
	
function configHostname() {
# Config the hostname for admin01.

	echo
	echo "*** Config the hostname"
	hostnamectl set-hostname ${ADMIN_HOST}

	# Copy in cloud.cfg to prevent overwrite of hostname
	cp ${ETCDIR}/cloud.cfg /etc/cloud/cloud.cfg
}

function installAmbari() {
# Config ambari 
# When running the ambari-server setup accept the defaults

	echo 
	echo "*** Download the Ambari repo file for yum"
	wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/${AMBARI_VER}/ambari.repo -O /etc/yum.repos.d/ambari.repo

	# Validate the repo file
	yum repolist
	echo -n "Is this correct?"
	checkContinue

	# Install Ambari code
	echo
	echo "*** Install Ambari Server"
	yum -y install ambari-server

	# Setup Ambari
	echo
	echo "*** Setup the Ambari Server"
	echo "Accept all of the defaults for the Oracle JDK and "
	echo "the Ambari database name. Do not use the advance Ambari"
	echo "database configurations."
	echo -n "Continue?"
	checkContinue
	ambari-server setup
}

function installJDBC() {
        echo "***Install PostgreSQL JDBC"
        yum -y install postgresql-jdbc*
        chmod 644 /usr/share/java/postgresql-jdbc.jar
        ls -l /usr/share/java/postgresql-jdbc.jar
}

function validateCentos() {
# Post the follow on instructions, primarily testing the success
# of the build.
        echo
        echo "***POST BUILD INSTRUCTIONS"
	echo "1. Reboot the server."	
	echo "2. Test the hostname"
	echo "  hostname "
	echo "  hostname -f"
	echo "3. Test DNS lookup and reverse lookup."
	echo "  dig admin01.private"
	echo "  dig -x 10.0.0.253"
	echo
}

function rebootServer() {
# Offer the choice to reboot the server.
        echo
        echo -n "Reboot?"
        checkContinue
	reboot
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkArgs 1

# Run configure 
intro
configBind
configHostname

# Run install
#installAmbari
#installJDBC

# Validate 
validateCentos
rebootServer
