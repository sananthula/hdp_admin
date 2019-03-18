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

# Title: startnifi.sh
# Purpose: This script starts up the Ambari server on the 
# NiFi instance. This script is called by setup-students.sh 
# script, which is run from any one of the nodes in the class.
# Author: WKD
# Date: 21AUG18
set -x

# VARIABLE

# FUNCTION
startDB() {
	ssh -tt node1 "/etc/init.d/postgresql restart"
}

startAmbari() {
# The ambari server will produce an error when connectiong 
# to port 8080. The message says access to port 8080 is denied. 
# REASON: Server not yet listening on http port 8080 after 50 seconds. Exiting.
# Connection to node1 closed. A second restart clears this error.

	ssh -tt node1 "/usr/sbin/ambari-server restart"
	sleep 5
	ssh -tt node1 "/usr/sbin/ambari-server restart"
}

# MAIN
startDB
startAmbari
