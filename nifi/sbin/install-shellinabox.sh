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

# Title: install-shellinabox.sh
# Purpose: This script installs Ubuntu shellinabox. This is only
# meant as a work around when port 22 is not available and when
# Guacamole does not provide connectivity.
# This script is installed on all instances of NiFi, but must
# be called from a master script called setup-students.sh.
# Author: WKD
# Date: 21AUG18
set -x

# VARIABLE
SHELLUSER=remote
DEBIAN_FRONTEND= noninteractive

# FUNCTION
installShell() {
	wget http.us.debian.org/debian/pool/main/s/shellinabox/shellinabox_2.14-1_amd64.deb
	dpkg -i shellinabox_2.14-1_amd64.deb
	sed -i.bak "s/\-\-no\-beep/\-\-no\-beep  \-\-disable\-ssl/g" /etc/default/shellinabox
	service shellinabox restart
}

addUser() {
	adduser --disabled-password --quiet --gecos ""  ${SHELLUSER}
	echo "remote:D3skt0p" | chpasswd
}

# MAIN
installShell
addUser
