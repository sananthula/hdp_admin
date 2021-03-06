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

# Name: build-centos.sh
# Author: WKD 
# Date: 18 Aug 2017
# Purpose: This is a build script to create a baseline server.
# Run this script on a EC2 instance to create a baseline
# server, gold image, and then create an AMI baseline on AWS.
# Before running this script you must copy into the working directory 
# the build-centos.sh script, the bashrc, the bash_profile, and the 
# authorized_key file, ie the public key. 

# CHANGES
# 01 Mar 2018 Release to HWU
# 18 Aug 2017 Major overhaul of script for HDP 2.3
# 12 Feb 2016 Changed user to eduadmin
# 17 Nov 2014 Created first script
# 28 Oct 2018 Updated for HDP 3.0 using Centos 7.6 

# VARIABLES
NUMARGS=$#
ADMIN_USER=$1
ADMIN_HOME=/home/${ADMIN_USER}
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE=${LOGDIR}/setup-ssl-ca-${DATETIME}.log

# FUNCTIONS
function usage() {
# usage
	echo "Usage: sudo $(basename $0) [admin_user]"
	exit 
}

function callFunction() {
# Test for script and run functions

        if [ -f /tmp/functions.sh ]; then
                source /tmp/functions.sh
        else
                echo "ERROR: The file /tmp/functions not found."
                echo "This required file provides supporting functions."
        fi
}

function intro() {
# Intro remarks.
	echo "This script will build a baseline server.You must have a copy"
	echo "of the bash_profile, bashrc, and the authorized key located"
	echo -n "in /tmp. Continue"
	checkContinue
}

function setNTP() {
# Set the Network Time Protocol. This is important for inter node 
# communications. 
	echo "***Install and configure NTP"
	yum install -y ntp
	systemctl enable ntpd
	systemctl start ntpd
	
	# set ulimit to 10000
	ulimit -n 10000
}

function setFirewall() {
# Turn off ip tables firewall for Linux 7.
# You can restart this after the setup is complete. But it is typically
# left off.
	echo
	echo "***Turn off firewalld"
	systemctl stop firewalld 
	systemctl disable firewalld	
}

function setSELinux() {
# Disable SELinux, this is required within our Hadoop cluster.
	echo
	echo "***Disable SELinux"
	setenforce 0
	sed 's/enforcing/disabled/' /etc/selinux/config > /tmp/selinux.tmp
	cp /tmp/selinux.tmp /etc/selinux/config
	rm /tmp/selinux.tmp
}

function installBind() {
# Install the bind utils for all servers
	echo
	echo "***Install bind"
	yum -y install bind bind-utils
}

function installCompression() {
# Run a script on the remote nodes
		echo
                echo "Install yum install compression"
                sudo yum -y install snappy snappy-devel
                sudo yum -y install lzo lzo-devel hadoop-lzo hadoop-lzo-native
}

function installJDK() {
# If you elect to install Open JDK then you will need to install the JDK 
# manually. In this environment we will use Oracle JDK and this will be 
# installed by Ambari
	echo
	echo "***Install OpenJDK"
	yum install -y java-1.8.0-openjdk
	yum install -y java-1.8.0-openjdk-devel
	yum install -y java-1.8.0-openjdk-headless
}

function updateYum() {
# Update packages and add additional packages as required. 
	echo
	echo "***Updating software with yum"
	yum install -y epel-release
	yum install -y vim wget
	yum update -y
}

function createAdmin() {
# Create the administrative user eduadmin. This is the primary administrator 
# for the cluster. Ensure access to root through sudo without a password.
	echo
	echo "***Create admin user ${ADMIN_USER}"
	groupadd -g 1500 ${ADMIN_USER}
	useradd -u 1500 -g 1500 -c "Hadoop Admin" -p "BadPass#1" ${ADMIN_USER}
	# This locks the password
	usermod -L ${ADMIN_USER}

	# Wheel group for sudo
	# This allows us to have sudo access with no password. This is an admin
	usermod -aG wheel ${ADMIN_USER}

	# environmental decision.
	sed -e '/NOPASSWD/s/# %wheel/%wheel/' /etc/sudoers > /tmp/sudoers.tmp
	cp /tmp/sudoers.tmp /etc/sudoers
	rm /tmp/sudoers.tmp
}

function setupAdmin() {
# Setup the admin user $admin
# This will only work if a copy of the bashrc and authorized_keys file are 
# located in /tmp.

	# setup bashrc
	if [ -f /tmp/bashrc ]; then
		cp /tmp/bash_profile ${ADMIN_HOME}/.bash_profile
		cp /tmp/bashrc ${ADMIN_HOME}/.bashrc
	fi

	# setup public keys access 
	if [ ! -d ${ADMIN_HOME}/.ssh ]; then
		mkdir ${ADMIN_HOME}/.ssh
		chmod 700 ${ADMIN_HOME}/.ssh
	fi

	# Allow access to the admin user from the local host
	# This may be a security consideration for your environment
	if [ -f /tmp/authorized_keys ]; then
		cp /tmp/authorized_keys ${ADMIN_HOME}/.ssh/authorized_keys
		chown -R ${ADMIN_USER}:${ADMIN_USER} ${ADMIN_HOME}/.ssh
		chmod 600 ${ADMIN_HOME}/.ssh/authorized_keys
	fi

	# Make standard directories
	mkdir ${ADMIN_HOME}/etc ${ADMIN_HOME}/bin ${ADMIN_HOME}/sbin ${ADMIN_HOME}/tmp

	# change ownership
	chown -R ${ADMIN_USER}:${ADMIN_USER} ${ADMIN_HOME} 
}

function lockRoot() {
# Lock the root password, there should be no ssh access either. 
	echo
	echo "***Lock the root password"
	passwd --lock root
}

function createUsers() {
# Create the users. 
	echo
	echo "***Create users"
	for USR in raj_ops maria_dev holger_gov amy_ds; do
		groupadd demo 
		useradd -g demo -c "${USR}" ${USR} 

		# This locks the password
		usermod -L ${USR}

		# setup bashrc
		if [ -f ${WRKDIR}/etc/bashrc ]; then
			cp ${WRKDIR}/etc/bash_profile /home/${USR}/.bash_profile
			cp ${WRKDIR}/etc/bashrc /home/${USR}/.bashrc
			chown ${USR} /home/${USR}/.bash*
		fi
	done
}

function cleanUp() {
# Cleanup the working directory
        rm  /tmp/authorized_keys
        rm  /tmp/build-centos.sh
        rm  /tmp/bash_profile
        rm  /tmp/bashrc
}

function validateAdmin() {
# Post the follow on instructions, primarily testing the success 
# of the build.
	echo
	echo "***POST BUILD INSTRUCTIONS"
	echo "1. Login to hadoopadmin and test sudo."
	echo "2. Test with a reboot."
	echo "3. Build an AMI image."
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
checkRoot
checkArgs 1
checkFile bashrc
checkFile authorized_keys

# Run setups
intro
setNTP
setFirewall
setSELinux

# Run installs
installBind
installCompression
installJDK
updateYum

# Run user
createAdmin
setupAdmin
lockRoot
createUsers

# Validate 
cleanUp
validateAdmin
rebootServer
