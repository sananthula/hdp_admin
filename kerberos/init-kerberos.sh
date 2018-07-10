#!/bin/bash

# Hortonworks University
# This script is for training purposes only and is to be used only
# in support of approved Hortonworks University exercises. Hortonworks
# assumes no liability for use outside of our training environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Title: krb5init
# Author: WKD
# Date:  1MAR18
# Purpose: Admin script to assist in managing the Hadoop cluster
# and services. Used for start and stop Kerberos on
# the admin server.

# VARIABLES
NUMARGS=$#
OPTION=$1

# FUNCTIONS
function usage() {
    echo "Usage: sudo $(basename $0) [start|stop|restart|status]"
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

function initKerberos() {
# Init Kerberos KDC and Admin

    sudo systemctl $OPTION kr5kdc
    sudo systemctl $OPTION kadmin
}

# MAIN
# Source function
callFunction

# Run checks
checkSudo
checkArg 1

# Run init
initKerberos
