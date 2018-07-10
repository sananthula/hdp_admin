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
# Purpose: These scripts are written to support building and configuing 
# a HDP cluster. They also contain good examples of shell programming
# in a HDP environment. 
#
# Disclaimer. There is no guarantee that these scripts will work in 
# your environment, especially the security scripts. You will have to 
# modify them to meet your needs.
#
# Functional Programming. The architecture of these scripts is written
# to place the code into functions. The end of each script contains a
# MAIN holding the calls for the functions. This structure makes it
# easy to turn on and off functions. 
#
# Common Functions. There is a script file called functions.sh. This
# file contains all functions that are called repeatedly through out
# these scripts.
#
# Usage Statement. Most scripts contain a usage statement. 
# 
# Use of Sudo. It was a design decision to place sudo commands within the
# scripts rather than requiring sudo from the command line. The top
# end of every script checks for sudo access.
#
# Testing. There is a function, called setTest, which can be placed at 
# the top of any MAIN to invoke testing features.
