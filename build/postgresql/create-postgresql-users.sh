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

# Name: create-postgresql-users.sh
# Author: WKD 
# Date: 170824
# Purpose: This is a build script to create users and database for Hive,
# Oozie and Ranger
#

# CHANGES
# RFC-1274 Script Maintenance

# VARIABLES
NUMARGS=$#
ETCDIR=${HOME}/etc
PASSWORD=$1

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [password]"
        exit 1
}

function checkSudo() {
# Testing for sudo access to root
        sudo ls /root > /dev/null 2>&1
        RESULT=$?
        if [ $RESULT -ne 0 ]; then
                echo "ERROR: You must have sudo to root to run this script"
                usage
        fi
}

function checkArg() {
# Check arguments exits
        if [ ${NUMARGS} -ne "$1" ]; then
                usage 
        fi
}

function createHive() {
# Config hive user and database
	echo
	echo "*** Config the hive user and database."

	echo 'BadPass#1' | sudo su -  postgres bash -c "psql -c \"CREATE USER hive WITH PASSWORD 'BadPass#1';\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"CREATE DATABASE hive WITH OWNER hive ENCODING 'UTF8' TEMPLATE template0;\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE hive to hive;\""
}
	
function createOozie() {
# Config oozie user and database
	echo
	echo "*** Config the oozie user and database."

	echo 'BadPass#1' | sudo su -  postgres bash -c "psql -c \"CREATE USER oozie WITH PASSWORD 'BadPass#1';\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"CREATE DATABASE oozie WITH OWNER oozie ENCODING 'UTF8' TEMPLATE template0;\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE oozie to oozie;\""
}

function createRanger() {
# Config rangeradmin user and the ranger database
	echo
	echo "*** Config the rangeradmin user and the ranger database."

	echo 'BadPass#1' | sudo su -  postgres bash -c "psql -c \"CREATE USER rangeradmin WITH PASSWORD 'BadPass#1';\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"CREATE DATABASE ranger WITH OWNER rangeradmin ENCODING 'UTF8' TEMPLATE template0;\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE ranger TO rangeradmin;\""
}

function createRangerKMS() {
# Config rangerkms user and the rangerkms database
	echo
	echo "*** Config the rangerkms user and the rangerkms database."

	echo 'BadPass#1' | sudo su -  postgres bash -c "psql -c \"CREATE USER rangerkms WITH PASSWORD 'BadPass#1';\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"CREATE DATABASE rangerkms WITH OWNER rangeradmin ENCODING 'UTF8' TEMPLATE template0;\""
	echo 'BadPass#1' | sudo su - postgres bash -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE rangerkms TO rangerkms;\""
}

function postInstructions() {
function postInstructions() {
# Post instructions
	echo
	echo "*** Post Instructions"
	echo 
	echo "On the Ambari server you need to test for remote connections"
	echo "1. Test hive from the Ambari host"
	echo "   psql -h client01.private -U hive -d hive"
	echo "2. Test oozie from the Ambari host"
	echo "   psql -h client01.private -U oozie -d oozie"
	echo "3. Test ranger from the Ambari host"
	echo "   psql -h client01.private -U rangeradmin -d ranger"
	echo "4. Test rangerkms from the Ambari host"
	echo "   psql -h client01.private -U rangerkms -d rangerkms"
	echo
}

# MAIN

# Run checks
checkSudo
checkArg 1

# Run create
createHive
createOozie
createRanger

# Next steps
postInstructions
