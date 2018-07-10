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

# Title: run-pki.sh
# Author: WKD
# Date: 24JAN18
# Purpose: This is the front end script for enabling SSL
# encryption for a HDP cluster.

# VARIABLE
NUMARGS=$#
SSLDIR=${HOME}/sbin/ssl

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0)" 
        exit 
}

function callFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/functions.sh ]; then
                source ${HOME}/sbin/functions.sh
        else
                echo "ERROR: The file ${HOME}/sbin/functions not found."
                echo "This required file provides supporting functions."
	fi
}

function callSSLFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/ssl/ssl-functions.sh ]; then
                source ${HOME}/sbin/ssl/ssl-functions.sh
        else
                echo "ERROR: The file ssl-functions not found."
                echo "This required file provides supporting functions."
        fi
}

function showIntro() {
# Intro screen
	clear
	headingSSL
	echo "
 Purpose: This tool front ends a number of scripts to setup SSL 
 encryption for many of the components of the  HDP ecosystem.
 The primary purpose is for use by Hortonworks Education in
 our security courses.

 Disclaimer: Read the disclaimer at the top of each script.

 Guidance: The most likely path to success is to follow the order
 of the menu. You MUST run the setup CA and setup Keys first. These
 scripts must be run from the Ambari server. It is recommended to first
 stop the cluster and then the Ambari server. You will restart both
 the Ambari server and the cluster as you progress forward. This 
 project requires time, proceed methodically. 

 Validation. The results of each script must be validated. Do not 
 proceed forward if a setup has failed. Most scripts end with specific 
 steps for validation.

 Self Signed CA. This tool creates and uses a self-signed CA. To use
 this tool in production will require modified of the scripts for a 
 Internet or enterprise CA. 

"
	checkContinue
}

function showIntro2() {
# Intro screen
	clear
	headingSSL
	echo "
 Working Directory. The general strategy of this tool is to create
 a working directory on the Ambari server, generally this is 
 /home/centos/pki. The tool then builds all of the certifications and 
 jks stores in this working directory. Once the jks stores are built
 they are then copied over the network to all of the nodes in the
 clusters. This prevents having to copy private keys across the network.
 This process is repeated every time certificates and keys must be added 
 to the stores. It is recommended you keep this working directory and 
 all of its contents for future expansion of services. Note this 
 directory must be highly secured and should only be located on the
 Ambari server.  

 Variables. This tool uses a common set of variables throughout. 
 These variables are set once per session and then exported for
 the following scripts. If you make a hash of it you will have to
 clean out all of the files and start in a new shell.

 Passwords. For simplicity of education we use only four passwords 
 through out the setup of SSL. A production installation may require 
 many more passwords. At a minimum you need seperate passwords for 
 the Ambari user, the CA key, the private keys, and the jks stores. 
 These scripts will provide you the minimum password configuration.

 Adding Hosts. The tool is designed to allow for the addition
 of new hosts into the cluster. You should be able to safely run
 the setup scripts again after adding new hosts. It should not
 overwrite existing certs or jks stores.
"
	checkContinue
}

function showIntro3() {
# Intro screen
	clear
	headingSSL
	echo "
 Tutorial. If you are unfamiliar with openssl and keytool, 
 we recommend you complete the tutorial for SSL first. This will
 give you a basic understanding of how these commands work. The
 tutorial should be a script titled run-ssl-tutorial.sh
	"
}

function showMenu() {
	clear
	headingSSL

	echo "  
 1. Setup PKI for Certificate Authority
 2. Setup PKI for Hadoop
 3. Setup PKI for Ambari
 4. Setup PKI for Oozie
 5. Setup PKI for Ranger
 6. Setup PKI for Atlas
 7. Setup PKI for Knox
 8. Overview of SSL for Hadoop 
"
	read -p "Enter your selection (q to quit): " OPTION junk
	
	# If there is an empty OPTION (Pressing ENTER) redisplays
	[ "${OPTION}" = "" ] && continue
}

function runOption() {
 	case $OPTION in
		1) ${SSLDIR}/setup-pki-ca.sh
		   ;;
		2) ${SSLDIR}/setup-pki-hadoop.sh
		   ;;
		3) ${SSLDIR}/setup-pki-ambari.sh
		   ;;
		4) ${SSLDIR}/setup-pki-oozie.sh
		   ;;
		5) ${SSLDIR}/setup-pki-ranger.sh
		   ;;
		6) ${SSLDIR}/setup-pki-atlas.sh
		   ;;
		7) ${SSLDIR}/setup-pki-knox.sh
		   ;;
		8) showIntro
		   showIntro2
		   showIntro3
		   ;;
		q*|Q*) clear; 
	   	   quit 0
		   ;;
		*) echo "Incorrect entry, please try again"
		   ;;
        esac
}

function runMenu() {

	while true; do
		showMenu
		clear
		runOption
		pause
	done
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0

# Set Passwords
clear
headingSSL
setPKIPass

# Run menu
runMenu
