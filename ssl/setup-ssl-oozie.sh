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

# Title: setup-ssl-oozie.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups SSL encryption for Oozie. Oozie requires
# a unique certificate, it must consist of only the domain from the DNS
# of the cluster.
# Note: This script must be run on the Ambari server.
# Note: The setup for Hadoop SSL must be run first.

# VARIABLE
NUMARGS=$#
DOMAIN=$(hostname -d)

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
	LOGFILE=${LOGDIR}/setup-ssl-oozie-${DATETIME}.log
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

function stopService() {
# Stop the Oozie service 

	echo "Use Ambari to stop the Ooozie service."
	echo -n "The domain is set to ${DOMAIN}."
	checkContinue
}

function configAmbari() {
# Configure Ambari to set oozie.base.url and add OOZIE_HTTP(S)_PORT

    	/var/lib/ambari-server/resources/scripts/configs.sh -u ${AMBARIADMIN} -p ${AMBARIPASS} -port 8443 -s set ${AMBARISERVER} ${CLUSTER} oozie-site oozie.base.url https://${OOZIE_ONE}:11443/oozie &> /dev/null

    	/var/lib/ambari-server/resources/scripts/configs.sh -u ${AMBARIADMIN} -p ${AMBARIPASS}  -port 8443 -s get ${AMBARISERVER} ${CLUSTER} oozie-env oozie-env
    	perl -pe 's/(\"content\".*?)\",$/$1\\nexport OOZIE_HTTP_PORT=11000\\nexport OOZIE_HTTPS_PORT=11443\",/' -i oozie-env

     	/var/lib/ambari-server/resources/scripts/configs.sh -u ${AMBARIADMIN} -p ${AMBARIPASS} -port 8443 -s set ${AMBARISERVER} ${CLUSTER} oozie-env oozie-env &> /dev/null


        echo "Set Ambari Infra and Metrics properties and values in Ambari." | tee -a ${LOGFILE}

cat <<EOF | setAmbari
    	oozie-env content \n#!/bin/bash\n\nif [ -d \"/usr/lib/bigtop-tomcat\" ]; then\n  export OOZIE_CONFIG=${OOZIE_CONFIG:-{{conf_dir}}}\n  export CATALINA_BASE=${CATALINA_BASE:-{{oozie_server_dir}}}\n  export CATALINA_TMPDIR=${CATALINA_TMPDIR:-/var/tmp/oozie}\n  export OOZIE_CATALINA_HOME=/usr/lib/bigtop-tomcat\nfi\n\n#Set JAVA HOME\nexport JAVA_HOME={{java_home}}\n\nexport JRE_HOME=${JAVA_HOME}\n\n# Set Oozie specific environment variables here.\n\n# Settings for the Embedded Tomcat that runs Oozie\n# Java System properties for Oozie should be specified in this variable\n#\n{% if java_version < 8 %}\nexport CATALINA_OPTS=\"$CATALINA_OPTS -Xmx{{oozie_heapsize}} -XX:MaxPermSize={{oozie_permsize}}\"\n{% else %}\nexport CATALINA_OPTS=\"$CATALINA_OPTS -Xmx{{oozie_heapsize}} -Dsun.security.krb5.rcache=none\"\n{% endif %}\n# Oozie configuration file to load from Oozie configuration directory\n#\n# export OOZIE_CONFIG_FILE=oozie-site.xml\n\n# Oozie logs directory\n#\nexport OOZIE_LOG={{oozie_log_dir}}\n\n# Oozie pid directory\n#\nexport CATALINA_PID={{pid_file}}\n\n#Location of the data for oozie\nexport OOZIE_DATA={{oozie_data_dir}}\n\n# Oozie Log4J configuration file to load from Oozie configuration directory\n#\n# export OOZIE_LOG4J_FILE=oozie-log4j.properties\n\n# Reload interval of the Log4J configuration file, in seconds\n#\n# export OOZIE_LOG4J_RELOAD=10\n\n# The port Oozie server runs\n#\nexport OOZIE_HTTP_PORT=11000\nexport OOZIE_HTTPS_PORT=11443\nexport OOZIE_HTTPS_KEYSTORE_FILE=KEYSTORELOC\nexport OOZIE_HTTPS_KEYSTORE_PASS=\"KEYPASS\"\n\n\n# The admin port Oozie server runs\n#\nexport OOZIE_ADMIN_PORT={{oozie_server_admin_port}}\n\n# The host name Oozie server runs on\n#\nexport OOZIE_HTTP_HOSTNAME=`hostname -f`\n\n# The base URL for callback URLs to Oozie\n#\n# export OOZIE_BASE_URL=\"https://${OOZIE_HTTP_HOSTNAME}:${OOZIE_HTTP_PORT}/oozie\"\nexport JAVA_LIBRARY_PATH={{hadoop_lib_home}}/native/Linux-{{architecture}}-64\n\n# At least 1 minute of retry time to account for server downtime during\n# upgrade/downgrade\nexport OOZIE_CLIENT_OPTS=\"${OOZIE_CLIENT_OPTS} -Doozie.connection.retry.count=5 \"\n\n{% if sqla_db_used or lib_dir_available %}\nexport LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH:{{jdbc_libs_dir}}\"\nexport JAVA_LIBRARY_PATH=\"$JAVA_LIBRARY_PATH:{{jdbc_libs_dir}}\"\n{% endif %},
    	oozie-site oozie.base.url https://{{oozie_server_host}}:11443
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Validate by using Ambari to restart the Oozie service."
	echo "3. Validate the SSL connection from a remote host."
	echo "    openssl s_client -connect ${OOZIE_ONE}:11443 -showcerts  < /dev/null"
	echo "4. To setup a remote Oozie client, you will have to copy over"
	echo "   the oozie.crt file." 
	echo "   scp /home/centos/ssl/oozie.crt /home/wkd/oozie.crt"
	echo "5. Then import the oozie.crt file into the Java keystore"
	echo "    sudo keytool -import -file /home/wkd/oozie.crt -alias tomcat"
	echo " -keystore /etc/pki/java/cacerts"
	echo "6. Validate that Oozie jobs will run." 
	echo "    oozie jobs -oozie  https://${OOZIE_ONE}:11443/oozie"
	echo
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkArg 0
checkAmbari
stopService

# Run setups
setupLog
setCertVar
setPKIPass
setServer

# Create Domain CRT
createDomainKey
createDomainCrt

# Create Oozie keystore
createOozieKey
importOozieKey
moveOozieKeystore

# Import Oozie public key to Hadoop keystores
importKey

# Move Hadoop keystores
moveKeystore

# Config Ambari
configAmbari
cleanupAmbari

# Next steps
validateSSL
