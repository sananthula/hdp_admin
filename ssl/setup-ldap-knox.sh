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

# Title: setup-ldap-knox.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups LDAP for the Knox  Gateway. 
# Note: Ensure you set the variables LDAP_SERVER, SYSTEM_USER
# and SEARCH_BASE for your environment.
# Note: This script must be run on the Ambari server.

# VARIABLE
NUMARGS=$#
GATEWAY=/usr/hdp/current/knox-server
LDAP_SERVER=ad01.lab.hortonworks.net
SYSTEM_USER=cn=ldap-reader,ou=ServiceUsers,dc=lab,dc=hortonworks,dc=net
SEARCH_BASE=ou=CorpUsers,dc=lab,dc=hortonworks,dc=net

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
                echo "ERROR: The file ${HOME}/sbin/functions.sh not found."
                echo "This required file provides supporting functions."
	fi
	LOGFILE=${LOGDIR}/setup-ldap-knox-${DATETIME}.log
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

function setServer() {
# Set variable for either one or two Knox Gateway servers, two servers 
# supports HA for Knox Gateway.

	if [ -z ${KNOX_SERVERS} ]; then	
		echo
		echo "WARNING WIP: This script is a work in progress (WIP), do not use."
		echo -n "IMPORTANT: Stop the Knox service before implementing SSL."
		pause
		echo
        	while : ; do
                	echo "Enter the FQDN for the servers. Press <ENTER> if none."
                	read -p "Enter the first Knox Gateway server: " KNOX_ONE
               		# read -p "Enter the second Knox Gateway server: " KNOX_TWO
			KNOX_SERVERS=$(echo ${KNOX_ONE} " " ${KNOX_TWO})
                	echo -n "The Knox Gateway servers are: ${KNOX_SERVERS}"
                	checkCorrect
        	done
	fi
}

# FUNCTIONS TO SETUP LDAP FOR KNOX GATEWAY
function createLdapPass() {
# Create a LDAP password for Knox Gateway, this must be done on each 
# Knox Gateway server

	echo "Create the certificate for Knox Gateway" | tee -a ${LOGFILE}	
	ssh -tt ${KNOX_ONE} -C "sudo -u knox ${GATEWAY}/bin/knoxcli.sh create-alias knoxLdapSystemPassword --cluster default --value ${KEY_PASSWORD}" >> ${LOGFILE} 2>&1
}

function configAmbari() {
# Required configurations changes for Ambari. Most of these should
# be left at the default. Change these only after careful research.

	echo "Set Hadoop properties and values in Ambari." | tee -a ${LOGFILE}

# WKD: Find the Knox default file name and the param 
cat <<EOF | setAmbari
	default default.topology   "
<topology>
        <gateway>
                <provider>
                        <role>authentication</role>
                        <name>ShiroProvider</name>
                        <enabled>true</enabled>
                        <param>
                                <name>sessionTimeout</name>
                                <value>30</value>
                        </param>
                        <param>
                                <name>main.ldapRealm</name>
                                <value>org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm</value>
                        </param>
                        <!-- changes for AD/user sync -->
                        <param>
                                <name>main.ldapContextFactory</name>
                                <value>org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory</value>
                        </param>
                        <!-- main.ldapRealm.contextFactory needs to be placed before other main.ldapRealm.contextFactory* entries  -->
                        <param>
                                <name>main.ldapRealm.contextFactory</name>
                                <value>$ldapContextFactory</value>
                        </param>
                        <!-- AD url -->
                        <param>
                                <name>main.ldapRealm.contextFactory.url</name>
                                <value>ldap://${LDAP_SERVER}:389</value>
                        </param>
                        <!-- system user -->
                        <param>
                                <name>main.ldapRealm.contextFactory.systemUsername</name>
                                <value>${SYSTEM_USER}</value>
                        </param>
                        <!-- pass in the password using the alias created earlier -->
                        <param>
                                <name>main.ldapRealm.contextFactory.systemPassword</name>
                                <value>${ALIAS=knoxLdapSystemPassword}</value>
                        </param>
                        <param>
                                <name>main.ldapRealm.contextFactory.authenticationMechanism</name>
                                <value>simple</value>
                        </param>
                        <param>
                                <name>urls./**</name>
                                <value>authcBasic</value>
                        </param>
                        <!--  AD groups of users to allow -->
                        <param>
                                <name>main.ldapRealm.searchBase</name>
                                <value>${SERACH_BASE}</value>
                        </param>
                        <param>
                                <name>main.ldapRealm.userObjectClass</name>
                                <value>person</value>
                        </param>
                        <param>
                                <name>main.ldapRealm.userSearchAttributeName</name>
                                <value>sAMAccountName</value>
                        </param>
                        <!-- changes needed for group sync-->
                        <param>
                                <name>main.ldapRealm.authorizationEnabled</name>
                                <value>true</value>
                        </param>
                        <param>
                                <name>main.ldapRealm.groupSearchBase</name>
                                <value>${SEARCH_BASE}</value>
                        </param>
                        <param>
                                <name>main.ldapRealm.groupObjectClass</name>
                                <value>group</value>
                        </param>
                        <param>
                                <name>main.ldapRealm.groupIdAttribute</name>
                                <value>cn</value>
                        </param>
</provider>

                <provider>
                        <role>identity-assertion</role>
                        <name>Default</name>
                        <enabled>true</enabled>
                </provider>

                <provider>
                        <role>authorization</role>
                        <name>XASecurePDPKnox</name>
                        <enabled>true</enabled>
                </provider>

                <!-- Knox HaProvider for Hadoop services -->
                <provider>
                        <role>ha</role>
                        <name>HaProvider</name>
                        <enabled>true</enabled>
                        <param>
                                <name>WEBHCAT</name>
                                <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true</value>
                        </param>
                        <param>
                                <name>HIVE</name>
                                <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true;zookeeperEnsemble=machine1:2181,machine2:2181,machine3:2181; zookeeperNamespace=hiveserver2</value>
                        </param>
                        <param>
                                <name>OOZIE</name>
                                <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true</value>
                        </param>
                        <param>
                                <name>HBASE</name>
                                <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true</value>
                        </param>
                </provider>
                <!-- END Knox HaProvider for Hadoop services -->
        </gateway>

        <service>
                <role>NAMEHOST</role>
                <url>hdfs://{{namenode_host}}:{{namenode_rpc_port}}</url>
        </service>

        <service>
                <role>JOBTRACKER</role>
                <url>rpc://{{rm_host}}:{{jt_rpc_port}}</url>
        </service>

        <service>
                <role>WEBHDFS</role>
                {{webhdfs_service_urls}}
        </service>

        <service>
                <role>WEBHCAT</role>
                <url>http://{{webhcat_server_host}}:{{templeton_port}}/templeton</url>
        </service>

        <service>
                <role>WEBHCAT</role>
                <url>http://{{webhcat_server_host}}:{{templeton_port}}/templeton</url>
        </service>

        <service>
                <role>OOZIE</role>
                <url>http://{{oozie_server_host}}:{{oozie_server_port}}/oozie</url>
        </service>

        <service>
                <role>WEBHBASE</role>
                <url>http://{{hbase_master_host}}:{{hbase_master_port}}</url>
        </service>

        <service>
                <role>HIVE</role>
                <url>http://{{hive_server_host}}:{{hive_http_port}}/{{hive_http_path}}</url>
        </service>

        <service>
                <role>RESOURCEMANAGER</role>
                <url>http://{{rm_host}}:{{rm_port}}/ws</url>
        </service>

        <service>
                <role>DRUID-COORDINATOR-UI</role>
                {{druid_coordinator_urls}}
        </service>

        <service>
                <role>DRUID-COORDINATOR</role>
                {{druid_coordinator_urls}}
        </service>

        <service>
                <role>DRUID-OVERLORD-UI</role>
                {{druid_overlord_urls}}
        </service>

        <service>
                <role>DRUID-OVERLORD</role>
                {{druid_overlord_urls}}
        </service>

        <service>
                <role>DRUID-ROUTER</role>
                {{druid_router_urls}}
        </service>

        <service>
                <role>DRUID-BROKER</role>
                {{druid_broker_urls}}
        </service>

        <service>
                <role>ZEPPELINUI</role>
                {{zeppelin_ui_urls}}
                </service>

        <service>
                <role>ZEPPELINWS</role>
                {{zeppelin_ws_urls}}
        </service>

</topology>
"
EOF
}

function validateLDAP() {
# Steps to validate

        echo
        echo "Validate:"
        echo "1. Review the logs at ${LOGFILE}."
        echo "2. Test by using curl from the Knox Gateway server."
	echo "    sudo curl -ik -u sales1:BadPass#1 https://localhost:8443/gateway/default/webhdfs/v1/?op=LISTSTATUS"
	echo "3. Test by using curl from the Ambari server."
	echo "    sudo curl -ik -u sales1:BadPass#1 https://${KNOX_ONE}:8443/gateway/default/webhdfs/v1/?op=LISTSTATUS"
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0
checkAmbari

# Run setups
setupLog ${LOGFILE}
setPKIPass
setServer

# Run
createLdapPass
configAmbari

# Validate
validateSSL
