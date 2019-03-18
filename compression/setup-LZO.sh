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

# Name: setupLZO.sh
# Author: WKD  
# Date: 1MAR18
# Admin script to assist in managing the Hadoop cluster
# and services. 
# Used to install LZO through out the cluster 

# CAUTION: You must have previously built the jar files for hadoop-LZO 

# CHANGES
# RFC-1274 Script Maintenance 

# VARIABLES
hostfile=/etc/hosts
target1=/home/hdadmin/src/java/hadoop-lzo/target/hadoop-lzo-0.4.20-SNAPSHOT.jar
target2=/home/hdadmin/src/java/hadoop-lzo/target/native/Linux-amd64-64/*

# FUNCTIONS
usage() {
	echo "Usage: $(basename $0) " 1>&2
	exit 2
}

function callInclude() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/include.sh ]; then
                source ${HOME}/sbin/include.sh
        else
                echo "ERROR: The file ${HOME}/sbin/include.sh not found."
                echo "This required file provides supporting functions."
        fi
}

checkArg() {
# Check args

        if [ $numargs -ne "$1" ]; then
                usage 1>&2
        fi
}

function intro() {
# Intro statement to set build

	read -p "Have you run buildLZO.sh? (Y/N) " ans
	if [[ $ans == "Y" || $ans == "y" ]]; then
        	echo    
	else
        	echo "ERROR: You must first run install-LZO.sh"
        	exit 1
	fi
}

function installdata() {
# Install LZO on every node in the cluster 

	while read -r f1 f2 f3 f4; do
        	[[ $f2 == data* ]] && ssh root@$f2 yum -y install lzo lzo-devel < /dev/null
		echo "***Installing hadoop-lzo files"
        	[[ $f2 == data* ]] && scp $target1 root@$f2:/usr/lib/hadoop/lib < /dev/null
        	[[ $f2 == data* ]] && scp $target2/* root@$f2:/usr/lib/hadoop/lib/native < /dev/null
	done < $hostfile
}

function validate() {
# Validate instructions

	echo
	echo "***POST BUILD INSTRUCTIONS"
	echo
	echo "1. Update core-site.xml and mapred-site.xml"
	echo "2. Push these to all nodes"
	echo "3. Restart the cluster. "
	echo
}

# MAIN 
# Source functions
callInclude

# Checks
checkArg 0

# Run
intro
installmaster
installdata
installclient
installadmin
validate
