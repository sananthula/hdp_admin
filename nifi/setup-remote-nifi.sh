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

# IMPORTANT ENSURE JAVA_HOME and PATH are set for root

# Name: setup-remote-nifi.sh
# Author: WKD
# Date: 26JAN19
# Purpose: This script installs a remote NiFi from the tar file
# We have to copy in the tar file onto the Ubuntu server and then
# onto the client designated to be the remote NiFi.
# Copy and run this script to the client designated
# to support a remote NiFi.
#set -x

# VARIABLES
NIFI_VER=nifi-1.5.0

# FUNCTIONS
function download() {
	mkdir /opt/nifi
	tar -xvf /opt/${NIFI_VER}-bin.tar -C /opt/nifi
	ln -s /opt/nifi/${NIFI_VER} /opt/nifi/current
}

function configure() {
 	cp /opt/nifi/current/conf/nifi.properties /opt/nifi/current/conf/nifi.properties.org
	sed -i -e 's/8080/9090/g' /opt/nifi/current/conf/nifi.properties
	sed -i -e 's/nifi.remote.input.host=/nifi.remote.input.host=client03.hwu.net/g' /opt/nifi/current/conf/nifi.properties
	sed -i -e 's/nifi.remote.input.socket.port=/nifi.remote.input.socket.port=8055/g' /opt/nifi/current/conf/nifi.properties
}

function start() {
	/opt/nifi/current/bin/nifi.sh start
	sleep 5
	/opt/nifi/current/bin/nifi.sh status
}

# MAIN
download
configure
start
