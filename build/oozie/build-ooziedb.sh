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

# Name: setupooziedb.sh
# Author: WKD 
# Date: Jun 30, 2015
# Purpose:

# VARIABLES
homedir=${HOME}
myhost="$(hostname) "

# FUNCTIONS
function checkRoot() {
	if [ "$(id -u)" != "0" ]; then
        	echo "ERROR: This script must be run using sudo" 1>&2
        	exit 1
	fi
}

function intro() {
	echo "You must push the Oozie configuration files before running this script."
	echo "Otherwise this script will fail to login to the database."
	echo
	read -p "Have you run createoozie.sql? (Y/N) " ans
	if [[ $ans != "Y" || $ans != "y" ]]; then
		echo "ERROR: You must first run createoozie.sql"
		exit 1 
	fi
}

function installOozieDB() {
# Command line to call for db schema to install metastore
# It is important this command runs as the user oozie
	sudo -u oozie /usr/lib/oozie/bin/ooziedb.sh create -run
}

function installOozieLib() {
# Create the hdfs user oozie and then install the shared libraries. 
	sudo -u hdfs hdfs dfs -mkdir /app/oozie
	sudo -u hdfs hdfs dfs -chown oozie:oozie /app/oozie
	sudo oozie-setup sharelib create -fs hdfs://master01:8020 -locallib /usr/lib/oozie/oozie-sharelib-yarn
}

function postInstructions() {
# Post the instructions for after the build is completed.
	echo
	echo "***POST BUILD INSTRUCTIONS"
	echo
	echo "1. Test oozie from the command line." 
	echo "2. Test oozie from a browser." 
	echo "3. Check hdfs /app/oozie for local lib." 
	echo "4. Run workflow."
}

# MAIN
checkRoot
intro
installOozieDB
installOozieLib
echo
echo "***"$myhost "completed " $0 
postInstructions
