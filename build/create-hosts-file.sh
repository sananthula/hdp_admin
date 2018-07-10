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

# Name: create-hosts-file.sh
# Author: WKD
# Date: 1MARl8
# Purpose: This script modifies /etc/hosts to create a set of hosts for
# our cluster. The hosts are named master, admin, client, and worker.
# These can be numbered from 01 to 99. The program appends IP 
# addresses and hostnames to a hosts file. This script does not 
# push the hosts file to the cluster.

# VARIABLES
NUMARGS=$#
ETCDIR=${HOME}/etc
HOSTS=${HOME}/etc/hosts.txt

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0)"
        exit 1 
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

function intro() {
	echo "This script is used to create the hosts.txt file,"
	echo "which is then used to push a new /etc/hosts file"
	echo "to all nodes in the cluster."
	echo

}
# Test an IP address for validity:
# Usage: checkip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#      if checkip IP_ADDRESS; then echo good; else echo bad; fi
#
function checkip() {
    local  IP=$1
    local  STAT=1

    if [[ ${IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        IP=($IP)
        IFS=$OIFS
        [[ ${IP[0]} -le 255 && ${IP[1]} -le 255 \
            && ${IP[2]} -le 255 && ${IP[3]} -le 255 ]]
        STAT=$?
    fi
    return $stat
}

function newHosts() {
# Create an origional back up of the /etc/hosts file.
    if [ ! -f "${ETCDIR}/hosts.bak" ]; then
	cp ${ETCDIR}/hosts.org ${HOSTS}
    fi
}

function echoCluster() {
	echo "# ***HDP Cluster***" >> ${HOSTS}
}

function serverType() {
# Allow the end-user to select server type.
	while : ;do
		read -p "Enter class of server master|admin|client|worker: " SERVERCLASS
		if [ ${SERVERCLASS} == "master" -o  ${SERVERCLASS} == "admin" -o ${SERVERCLASS} == "client" -o ${SERVERCLASS} == "worker" ]; then 
			break
		fi
	done
}

function addServers() {
# Add servers to the host file. Continue until completed.
	i=1
	while : ;do
		read -p "Enter number of $server servers (1-9): " LOOP
		if [[ ${LOOP} -ge 1 || ${LOOP} -le 9 ]]; then  
			break
		fi
	done

	while [ $i -le ${LOOP} ]; do
		SERVERCOUNT=${SERVERCLASS}"0"$i
		while : ; do
			read -p "Enter IP for ${SERVERCOUNT}: " ARRAY[$i]
			if checkip "${ARRAY[$i]}"; then
				break
			else
				echo -n  "ERROR: Incorrect IP format. "
			fi
		done

		if [[ ${ARRAY[$i]} == 10.* ]]; then
			echo "ERROR: EC2 IP do not start with 10"
			read -p "Enter IP for $servercount: " ARRAY[$i]
			if checkip "${ARRAY[$i]}"; then
				break
			else
				echo -n "ERROR: Incorrect IP format."
			fi
		fi

		((i++))
	done	
}

function validate() {
# It is important to validate the host file before submitting it as final.
	i=1
	echo	
	while [ $i -le ${LOOP} ]; do
		SERVERCOUNT=${SERVERCLASS}"0"$i
		echo ${ARRAY[$i]} " " ${SERVERCOUNT}".hortonworks.net" ${SERVERCOUNT}
		((i++))
	done
	
	echo -n  "Correct? "
	checkContinue
}

function add2HostsFile() {
# Now add the validated input into the host file.
	i=1
	if [[ ${YESNO} == "Y" || ${YESNO} == "y" ]]; then
		while [ $i -le ${LOOP} ]; do
			SERVERCOUNT=${SERVERCLASS}"0"$i
			echo ${ARRAY[$i]} ${SERVERCOUNT}".hortonworks.net" ${SERVERCOUNT} >> ${HOSTS}
			((i++))
		done
	else
		echo "Rerun $0 to correct entries"
		exit 1
	fi
}

function postInstructions() {
# Post the follow on instructions, primarily testing the success
# of the build.
        echo "        Next Steps"
        echo "1. Copy the hosts.txt to /etc/hosts"
	echo "  sudo cp ~/etc/hosts.txt /etc/hosts" 
        echo "2. Validate it with ssh to remote nodes"
	echo " 	 ssh master01"
	echo "   ssh worker01.hortonworks.net" 
        echo "3. Run the rename scrip to rename the hosts"
	echo "   rename-hosts.sh"
        echo "3. Important: Reboot all hosts and then validate hostnames"
	echo "   ssh master02"
	echo "   hostname"
	echo "   hostname -f"
	echo
}

# MAIN
callFunction

# Run checks
checkSudo
checkArgs 0

# Run 
intro
newHosts

# Loop
# Create a continuous loop until the end user decided to exit.
while : ; do
	serverType
	addServers
	validate
	add2HostsFile
	checkContinue
done

# Next steps
postInstructions
