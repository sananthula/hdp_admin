# Hortonworks University
# This script is for training purposes only and is to be used only
# in support of approved Hortonworks University exercises. Hortonworks
# assumes no liability for use outside of our training environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Title: README.txt 
# Author: WKD
# Date: 1MAR18
# Purpose: Provide notes on the scripts written to support configuing
# SSL for a HDP cluster.
# All scripts are written to be run as standalone; however, there
# are run scripts which provide menu driven front ends. 

Critical Errors:
	* Knox cycles warnings during startup, eventually timing out
	  and starting. We are currently using the instructions from
	  HWX docs. These use a CLI knoxcli.sh to genkey. We want to 
	  modify to use the Hadoop keystores.

Bugs:
	* Alert for Secondary NN continues to use HTTP
	* Alert for Ranger Usersync continues to use HTTP

Work in Progress:
	* Test Ambari truststore pointing to all.jks
	* Find the inputs name and parameter for Advanced Knox LDAP.
	* Determine the best strategy for SSL for Knox
		* This may resolve the critical error.
		* Knox cli does not provide password to keystore
		* Import cert into all.jks?

Next Release:
	* Build HA cluster for NN, RM, Hiveserver2, Oozie
	* Test SSL for HA for NN, RM, Hive, and Ooozie
	* Add support for multiple Ranger servers
	* Add support for multiple Knox Gateway servers

Features to Consider Requesting:
	* The ambari-server setup-ldap does not include options
	for password and convert, this is required for scripting
	* The ambari-server sync-ldap does not include options
	for user and password, this is required for scripting
	* Add the the above options or get ambari-server REST to work.
