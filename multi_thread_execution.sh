############################################################################################################################
# This script executes script : `script.sh` (presents in the same folder) to all nodes of a cluster.                       #
# See below exports to change node names and range, but also to allow printing of results or not.                          #
#                                                                                                                          #
# It creates a named, according to first parameter or default to timestamped, directory for each execution.                # 
# If set, it archives results at the end, with script.sh.                                                                  #
############################################################################################################################

echo "Start of script"

# Modify these below settings according to your cluster
export NODE_NAME='feng-'
export NODE_USER='root'
export NODE_NUMBERS_START=1
export NODE_NUMBERS_END=5
export PRINT_RESULTS=false
export DELETE_RESULTS=false
export ARCHIVE_RESULTS=false

# Create folder name to first argument passed or default to timestamp
if [ -z "$1" ]
then 
    export FOLDER_NAME=logs/$(date +%s)
else 
    export FOLDER_NAME=logs/$1
fi

PID_ARRAY=()

# Create directories of work
mkdir -p ${FOLDER_NAME}/
mkdir -p ${FOLDER_NAME}/results/

# Copy script that will be used in directory of work
cp script.sh ${FOLDER_NAME}/

# Execute the script on each node and redirect its output in an appropriate named file
for i in $(eval echo "{${NODE_NUMBERS_START}..${NODE_NUMBERS_END}}")
do
    echo "*************** Launch parallel execution on node ${NODE_NAME}${i} ***************"
    ssh ${NODE_USER}@${NODE_NAME}${i} 'bash -s' < ${FOLDER_NAME}/script.sh ${i} > ${FOLDER_NAME}/results/${NODE_NAME}${i}.out 2>&1 &
    PID_ARRAY+=($!)
done

# Wait for script on every node to complete
for p in $PID_ARRAY
do
    wait $p
done

# Wait to be sure, before archiving
sleep 2

# Archive all results in a tar if required
if [ "${ARCHIVE_RESULTS}" = true ]
then 
    echo "*************** Creating final archive ***************"
    tar -cvzf ${FOLDER_NAME}.tar  ${FOLDER_NAME}/* 
    echo "*************** Finished to create final archive ***************"
fi    

# Printing results ? 
if [ "${PRINT_RESULTS}" = true ]
then 
    echo "*************** Printing results ***************"
    for i in $(eval echo "{${NODE_NUMBERS_START}..${NODE_NUMBERS_END}}")
    do
        echo "*************** Results of node ${i} ***************"
        cat ${FOLDER_NAME}/results/${NODE_NAME}${i}.out
        echo "*************** End of results of node ${i} ***************"
    done
    echo "*************** Finished printing results ***************"
fi

# Deleting results ? 
if [ "${DELETE_RESULTS}" = true ]
then 
    rm -rf ${FOLDER_NAME}
fi

echo "End of script"

