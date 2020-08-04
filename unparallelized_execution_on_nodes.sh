############################################################################################################################
# This script executes script : `script.sh` (presents in the same folder) to all nodes of a cluster.                       #
# See below exports to change node names and range, but also to allow printing of results or not.                          #
#                                                                                                                          #
# It creates a named, according to first parameter or default to timestamped, directory for each execution.                # 
# If set, it archives results at the end, with script.sh.                                                                  #
############################################################################################################################

echo "Start of script"

# Modify these below settings according to your cluster
export NODE_NAME='fri2-'
export NODE_USER='root'
export NODE_NUMBERS_START=1
export NODE_NUMBERS_END=6
export PRINT_RESULTS=true
export ARCHIVE_RESULTS=false

# Create folder name to first argument passed or default to timestamp
if [ -z "$1" ]
then 
    export FOLDER_NAME=$(date +%s)
else 
    export FOLDER_NAME=$1
fi

# Create directories of work
mkdir ${FOLDER_NAME}/
mkdir ${FOLDER_NAME}/results/

# Copy script that will be used in directory of work
cp script.sh ${FOLDER_NAME}/

# Execute the script on each node and redirect its output in an appropriate named file
for i in $(eval echo "{${NODE_NUMBERS_START}..${NODE_NUMBERS_END}}")
do
    echo "*************** Launch execution on node ${NODE_NAME}${i} ***************"
    ssh -i ycloud-key ${NODE_USER}@${NODE_NAME}${i} 'bash -s' < ${FOLDER_NAME}/script.sh ${i} > ${FOLDER_NAME}/results/${NODE_NAME}${i}.out
done
