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

# Name: install-nifi-mpack.sh
# Author: WKD
# Date: 15FEB19
# Purpose: This script installs the NiFi mpack for Ambari
#set -x

# VARIABLES
NIFI_VER=hdf-ambari-mpack-3.1.2.0-7

# FUNCTIONS
function download() {
# Download the mpack

	mkdir /tmp/nifi
	cd /tmp/nifi
	wget -nv http://public-repo-1.hortonworks.com/HDF/centos7/3.x/updates/3.1.2.0/tars/hdf_ambari_mp/${NIFI_VER}.tar.gz
}

function install() {
# The following will be the output:
# Using python /usr/bin/python
# Installing management pack
# Ambari Server 'install-mpack' completed successfully.

	ambari-server install-mpack --mpack=/tmp/${NIFI_VER}.tar.gz
}

function restart() {
# Restart Ambari

	sleep 5
	ambari-server start
}

# MAIN
download
install
restart
