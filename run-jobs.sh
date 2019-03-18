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

# Name: run-jobs.sh
# Author: WKD  
# Date: 1MAR18
# Purpose: Provide MapReduce workload on the Hadoop cluster by running 
# a series of MR jobs in the background. This script is used to for 
# validation of YARN queues, YARN ACL's, and YARN default queue mappings.
# This tool is intended as a simple benchmark for fast comparision.
# This script sets the user and the job queue. This script runs one of 
# the following jobs [pi|wordcount|queue|container]. 
# For pi jobs adjust the number of loops, the number of mappers and 
# the number of calculations to increase stress on the cluster. 
# The time delay (sleep) between jobs should be adjusted to
# map to cluster resources and the configuration of
# the scheduler queues. 
#
# For wordcount set the number of loops, the input directory,
# and the output directory. When setting up for wordcount create a 
# hdfs://data/dirname directory and set the permissions to 777.
#
# For queue you may want to edit the function runqueuejob to adjust
# the number and location of the jobs.
#
# For container you will set the memory size for the mapper and for
# the reducer. Memory sizes must be in units of 1024, 2048, 3072, 4096,
# 5120, 6144, 7168, 8192, etc. A standard ratio is for the reducer memory
# to be twice that of the mapper.
#

# VARIABLES
NUMARGS=$#
JARFILE=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar
USER1=dev01
USER2=ops01
USER3=biz01
USER4=dev02
USER5=ops02
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE="${LOGDIR}/job-runner-${DATETIME}.log"

# FUNCTION
function usage() {
        echo "Usage: $(basename $0)" 1>&2
        exit 1
}

function callInclude() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/include.sh ]; then
                source ${HOME}/sbin/include.sh
        else
                echo "ERROR: The file ${HOME}/sbin/include.sh not found."
                echo "This required file provides supporting functions."
        fi
}

function intro() {
	echo "Job Runner may be a long running script."
	echo "If required terminate this script with Ctrl-C "
	echo
	read -p "Set the type of job to run [pi|wordcount|queue|container]: " OPTION
}

function setPiJobs() {
# Set job inputs

	read -p "Set name of job submitter: " USERNAME
        read -p "Set name of queue: " QUEUENAME
        read -p "Set number of job loops: " LOOPS
        read -p "Set seconds between jobs: " SECONDS
        read -p "Set number of mappers: " MAPPERS
        read -p "Set number of pi calculations: " CALCS
}

function runPiJobs() {
# Run the pi job in a loop

        for ((i=1;i <= ${LOOPS}; i++)) ; do
                echo
                echo "Starting cycle $i of ${LOOPS} at $(date +"%T")"
                echo >> ${LOGFILE}
                echo "****Cycle $i of ${LOOPS} at $(date +"%T")" >> ${LOGFILE}
                sudo -u ${USERNAME} nohup yarn jar ${JARFILE} pi -D mapreduce.job.queuename=${QUEUENAME} ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
                sleep ${SECONDS}
        done
}

function setWordJobs() {
# Set job inputs

	read -p "Set name of job submitter: " USERNAME
        read -p "Set name of queue: " QUEUENAME
	read -p "Set number of job loops: " LOOPS
	read -p "Set seconds between jobs: " SECONDS
	read -p "Set input directory: " INPUTDIR 
	read -p "Set output directory: " OUTPUTDIR
}

function runWordJobs() {
# Run wordcount jobs	

	for ((i=1;i <= ${LOOPS};i++)) ; do
		echo
        	echo "Starting cycle $i of ${LOOPS} at $(date +"%T")"
        	echo >> ${LOGFILE}
        	echo "****Cycle $i of ${LOOPS} at $(date +"%T")" >> ${LOGFILE}
		sudo -u ${USERNAME} nohup yarn jar ${JARFILE} wordcount -D mapreduce.job.queuename=${QUEUENAME} ${INPUTDIR} ${OUTPUTDIR}$i >> ${LOGFILE} 2>&1 &
		PID=$!
		echo pid equals $PID
		sleep ${SECONDS}
	done
}

function cleanOutDir() {
# Remove the output directories	

	for ((i=1;i <= ${LOOPS};i++)) ; do
        	echo "Deleting the output directory $i"
        	echo "****Deleting output directory $i" >> ${LOGFILE}
		wait $PID
		sudo -u ${USERNAME} hdfs dfs -rm -r -skipTrash /user/${USERNAME}/${OUTPUTDIR}$i >> ${LOGFILE} 2>&1
	done
}

function setQueueJobs() {
# Set job inputs

        read -p "Set number of job loops: " LOOPS
        read -p "Set seconds between jobs: " SECONDS
        read -p "Set number of mappers: " MAPPERS
        read -p "Set number of pi calculations: " CALCS
}

function runQueueJobs() {
# Run pi jops in different queues

	for ((i=1;i <= ${LOOPS};i++)) ; do
        	echo
        	echo "Starting cycle $i of ${LOOPS} at $(date +"%T")"
        	echo >> ${LOGFILE}
        	echo "****Cycle $i of ${LOOPS} at $(date +"%T")" >> ${LOGFILE}
        	sudo -u ${USER1} nohup yarn jar ${JARFILE} pi ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
        	sleep ${SECONDS}
        	sudo -u ${USER2} nohup yarn jar ${JARFILE} pi ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
        	sleep ${SECONDS}
        	sudo -u ${USER3} nohup yarn jar ${JARFILE} pi ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
        	sleep ${SECONDS}
        	sudo -u ${USER4} nohup yarn jar ${JARFILE} pi ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
        	sleep ${SECONDS}
        	sudo -u ${USER5} nohup yarn jar ${JARFILE} pi ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
        	sleep ${SECONDS}
done
}

function setContainerJobs() {
# Set job inputs

	read -p "Set name of job submitter: " USERNAME
        read -p "Set name of queue: " QUEUENAME
	echo "Memory: 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192" 
        read -p "Set mapper memory: " MAPRAM 
        read -p "Set reducer memory: " REDRAM 
        read -p "Set number of job {LOOPS}: " LOOPS
        read -p "Set seconds between jobs: " SECONDS
        read -p "Set number of mappers: " MAPPERS
        read -p "Set number of pi calculations: " CALCS
}

function runContainerJobs() {
# Run job to adjust JVM memory for mappers and reducers.

	for ((i=1;i <= ${LOOPS};i++)) ; do
		sudo -u ${USERNAME} nohup yarn jar ${JARFILE} pi -D mapreduce.job.queuename=${QUEUENAME} -D mapreduce.map.memory.mb=${MAPRAM} -D mapreduce.reduce.memory.mb=${REDRAM} ${MAPPERS} ${CALCS} >> ${LOGFILE} 2>&1 &
	done
}

function runOption() {
# Case statement for run jobs

        case "${OPTION}" in
                -h | --help)
                        usage
                        ;;
                pi)
			setPiJobs
			runPiJobs
                        ;;
                wordcount)
			setWordJobs
			runWordJobs
			cleanOutDir
                        ;;
                queue)
			setQueueJobs
			runQueueJobs
                        ;;
                container)
			setContainerJobs
			runContainerJobs
                        ;;
                *)
                        usage
                        ;;
        esac
}

# MAIN
# Source functions
callInclude

# Run checks
checkSudo

# Run setups
setupLog ${LOGFILE}

# Run option
trap "interrupt 1" 1 2 3 15
intro
runOption
