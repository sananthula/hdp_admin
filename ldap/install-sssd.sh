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

# Name: install-sssd.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Install and configure sssd for the support of OS connection
# to LDAP/AD. 
#
# Note: This script is intended to be run on every node in the cluster

# VARIABLES
NUMARGS=$#
PASSWORD=$1
ad_user="registersssd"
ad_domain="lab.hortonworks.net"
ad_dc="ad01.lab.hortonworks.net"
ad_root="dc=lab,dc=hortonworks,dc=net"
ad_ou="ou=HadoopNodes,${ad_root}"
ad_realm=LAB.HORTONWORKS.NET

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [Kerberos-password]" 
        exit 
}

function checkSudo() {
# Testing for sudo access to root

        sudo ls /root > /dev/null
        if [ "$?" != 0 ]; then
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

function initTGT() {
# Must kinit for Kerberos

	echo "${PASSWORD}" | sudo kinit ${ad_user}
	if [ $? -eq 1 ]; then
		usage
	fi
}

function installSSSD() {
# Install sssd software

	# Install cache
	sudo yum makecache fast

	# epel is required for adcli
	sudo yum -y -q install epel-release 
	sudo yum -y -q install authconfig adcli

	# Install sssd
	sudo yum -y -q install sssd sssd-krb5 sssd-ad sssd-tools oddjob-mkhomedir
}

function adCommand() {
# Run adcli

	sudo adcli join -v \
	--domain-controller=${ad_dc} \
	--domain-ou="${ad_ou}" \
	--login-ccache="/tmp/krb5cc_0" \
	--login-user="${ad_user}" \
	-v \
	--show-details
}

function createSSSDFile() {
# Note: The master & data nodes only require nss. 
# Edge nodes require pam. Configure sssd.conf

	sudo tee /etc/sssd/sssd.conf > /dev/null <<EOF
[sssd]
services = nss, pam, ssh, autofs, pac
config_file_version = 2
domains = ${ad_realm}
override_space = _

[domain/${ad_realm}]
id_provider = ad
ad_server = ${ad_dc}
#ad_server = ad01, ad02, ad03
#ad_backup_server = ad-backup01, 02, 03
auth_provider = ad
chpass_provider = ad
access_provider = ad
enumerate = False
krb5_realm = ${ad_realm}
ldap_schema = ad
ldap_id_mapping = True
cache_credentials = True
ldap_access_order = expire
ldap_account_expire_policy = ad
ldap_force_upper_case_realm = true

fallback_homedir = /home/%d/%u
default_shell = /bin/false
ldap_referrals = false

[nss]
memcache_timeout = 3600
override_shell = /bin/bash
EOF
}

function copySSSDFile() {
# This offers a choice for the configuration file. This
# function copies the file from the local etc directory instead
# of creating the function with EOF.

	sudo cp ${HOME}/etc/sssd.conf /etc/sssd/sssd.conf
}

function configSSSD() {
# Config sssd

	# Setup permissions on configuration files
	sudo chown root:root /etc/sssd/sssd.conf
	sudo chmod 0600 /etc/sssd/sssd.conf

	# Restart sssd
	sudo systemctl restart sssd

	# Setup chkconfig to ensure autostart of daemons
	sudo authconfig --enablesssd --enablesssdauth --enablemkhomedir --enablelocauthorize --update

	# Restart oddjobd
	sudo chkconfig oddjobd on
	sudo systemctl restart oddjobd 

	# Restart sssd
	sudo chkconfig sssd on
	sudo systemctl restart sssd
}


# MAIN
# Run checks
checkSudo
checkArg 1

# Kinit
initTGT

# Install sssd
installSSSD
adCommand
#createSSSDFile
copySSSDFile

# Config sssd
configSSSD

# Destroy Kerberos TGT
sudo kdestroy
