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

# Name: install-LZO.sh
# Author: WKD  
# Date: 1MAR18
# Purpose: Admin script to download and build the Hadoop library files
# for LZO to get LZO compression working for Hadoop.
# You must have a configured dev environment for this to work. 
# Run the scripts for configuring dev, setupDevEnv.sh

# CHANGES
# RFC-1274 Script Maintenance 

# VARIABLES

# FUNCTIONS
function testing() {
# Testing for Dev enviroment.
	wget -V &>/dev/null || echo "ERROR: No wget command"; exit 1
	git --version &>/dev/null || echo "ERROR: No git command"; exit 1
	gcc --version &>/dev/null || echo "ERROR: No gcc command"; exit 1
	mvn -v &>/dev/null || echo "ERROR: No mvn command";  exit 1
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

function installLZO() {
	# Yum package install the LZO dev lig
	sudo yum -y install lzo lzo-devel
}

function installHadoopLZO() {
	cd /home/hdadmin/src/java
	# Clone the hadoop-lzo from github
	git clone https://github.com/twitter/hadoop-lzo.git

	# Build and clean hadoop-lzo 
	cd hadoop-lzo
	mvn package

	# Place the hadoop-lzo-*.jar into your cluster path
	sudo cp target/hadoop-lzo-*SNAPSHOT.jar /usr/lib/hadoop/lib
	# Place the native hadoop-lzo binaries into hadoop native directory
	sudo cp target/native/Linux-amd64-64/lib/* /usr/lib/hadoop/lib/native 
}

function postInstructions() {
	echo
	echo "***POST BUILD INSTRUCTIONS"
	echo
	echo "1. Check the target directory under /home/hdadmin/src/java/hadoop-lzo/target."
	echo "2. Run jar tvf on hadoop-lzo*SNAPSHOT.jar to check for codec"
	echo "3. Run setupLZO.sh to distributed jar file across the cluster."
	echo
}

# MAIN
# Source functions
#callFunction

# Run install
testing
installLZO
installHadoopLZO

# Next steps
postInstructions
