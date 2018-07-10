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

# Name: setup-ambari-ldap.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Setup Ambari with Active Directory
# Changes:

#VARIABLES
ad_host=ad01.lab.hortonworks.net  
ad_root=ou=CorpUsers,dc=lab,dc=hortonworks,dc=net 
ad_user=cn=ldap-reader,ou=ServiceUsers,dc=lab,dc=hortonworks,dc=net

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

function configLDAP() {
# Set configuration file for ldap

	sudo ambari-server setup-ldap \
--ldap-url=${ad_host}:389 \
--ldap-secondary-url= \
--ldap-ssl=false \
--ldap-user-class=user \
--ldap-user-attr=sAMAccountName \
--ldap-group-class=group \
--ldap-group-attr=cn \
--ldap-dn=distinguishedName \
--ldap-base-dn=${ad_root} \
--ldap-referral= \
--ldap-bind-anonym=false \
--ldap-manager-dn=${ad_user} \
--ldap-member-attr=member \
--ldap-save-settings
}

# MAIN
# Source functions
callFunction

# Config LDAP
configLDAP

# pause "Restarting the ambari-server" 
sudo ambari-server restart
