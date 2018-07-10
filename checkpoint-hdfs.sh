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

# Title: checkpoint-hdfs.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script checkPoints the NameNode. 
# Alert. This can be done if the checkPoint alert comes out due 
# to no current checkPoint. This script should be run on the 
# ACTIVE NAMEHOST. The alert will clear.

# VARIABLE
NUMARGS=$#

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
}

function checkPoint() {
# Place NN in safemode and the merge editlogs into fsimage

	sudo -u hdfs hdfs dfsadmin -safemode enter
	sudo -u hdfs hdfs dfsadmin -saveNamespace
	sudo -u hdfs hdfs dfsadmin -safemode leave
}

# MAIN
# Source Functions
callFunction

# Run checks
checkSudo
checkArg 0

# Checkpoint
checkPoint
