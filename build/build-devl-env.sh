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

# Name: build-devl-env.sh
# Author: WKD  
# Date: 12 Feb 2015
# Admin script to setup Dev environment by downloading and installing
# various required packages. 
# Used to add gcc, curl, wget, ant, maven, and supporting libraries. 
# Ensure you check the version of Maven within this script.

# CHANGES
# RFC-1274 Script Maintenance 

# VARIABLES
mavenver=apache-maven-3.0.5
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE=${LOGDIR}/build-devl-env-${DATETIME}.log

# FUNCTIONS
function callFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/functions.sh ]; then
                source ${HOME}/sbin/functions.sh
        else
                echo "ERROR: The file ${HOME}/sbin/functions not found."
                echo "This required file provides supporting functions."
        fi
}

function installTools() {
# Install tools 
	sudo yum -y install vim 
	sudo yum -y install curl 
	sudo yum -y install wget
	sudo yum -y install zip unzip 
	sudo yum -y install bzip2 bzip2-devel
}

function installlibs() {
# Install libs 
	sudo yum -y install libxml2-devel
	sudo yum -y install libxsit-devel 
	sudo yum -y install libsqlite3-devel 
	sudo yum -y install libldap2-devel
}

function installDev() {
# Install dev tools
	sudo yum -y install gcc gcc-c++
	sudo yum -y install git
	sudo yum -y install ant
}

function installmaven() {
	cd /usr/share
	# Pull down the maven code
	sudo wget http://www.apache.org/dist/maven/binaries/$mavenver-bin.tar.gz

	# Extract maven
	sudo tar -zxvf $mavenver-bin.tar.gz

	# Create links
	sudo ln -s $mavenver maven

	# clean up
	sudo rm apache-maven-3.0.5-bin.tar.gz

	# add paths to .bashrc
    	echo -r "Do you want to modify hdadmin .bashrc for maven? (Y/N) " 
    	read ans
		if [ ans = "Y" -o ans = "y" ]; then
			echo export M2_HOME=/usr/local/maven >> ${HOME}/.bashrc
			echo export PATH=${PATH}:${M2_HOME}/bin >> ${HOME}/.bashrc
		fi

}

function installPython() {
# Install python tools
	sudo yum -y install python2.6-devel
	sudo yum -y install python-pip
}

function validateDevl() {
# Validate install

        echo
        echo "***POST BUILD INSTRUCTIONS"
        echo
        echo "1. Test you tools: curl, wget, zip, bzip2 ."
	echo "2. Test your dev tools: git, ant, gcc, maven."
        echo
}

# MAIN
# Source functions
callFunction

# Run install
installTools
installDev
[ mvn -v &> /dev/null ] || installmaven
installPython

# Next steps
validateDevl
