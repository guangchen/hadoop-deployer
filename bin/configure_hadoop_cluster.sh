#!/bin/bash

if [ $# != 1 ]; then
        echo "Script Usage: ./configure_hadoop_cluster.sh <path/to/node/file>"
        exit -1
fi

PBS_NODEFILE=$1

NODEFILE="$HADOOP_HOME/conf/nodefile"

NAMENODE_IPC_PORT=8020
NAMENODE_IPC_PORT=`$HADOOP_HOME/contrib/hadoop-deployer/bin/find_avail_port.sh $NAMENODE_IPC_PORT`

echo "namenode IPC server port is  $NAMENODE_IPC_PORT"

JOBTRACKER_IPC_PORT=`expr $NAMENODE_IPC_PORT + 1`
JOBTRACKER_IPC_PORT=`$HADOOP_HOME/contrib/hadoop-deployer/bin/find_avail_port.sh $JOBTRACKER_IPC_PORT`

echo "jobtracker IPC server port is  $JOBTRACKER_IPC_PORT"

# generate node file that lists each node, one per line
sort -u $PBS_NODEFILE > $NODEFILE

# the first node is used as master node
MASTER_NODE=`head -n 1 $NODEFILE`

echo "Uses $MASTER_NODE as master node"

SLAVE_NODE_FILE="$HADOOP_HOME/conf/slaves"
rm -rf $SLAVE_NODE_FILE

NUM_WORKERS=`wc -l $NODEFILE | awk '{print $1}'`
NUM_WORKERS=`expr $NUM_WORKERS - 1`

for line in `tail -n $NUM_WORKERS $NODEFILE`;do
	echo $line >> $SLAVE_NODE_FILE
done

# generate core-site.xml
sed -e 's|__hostname__|'$MASTER_NODE'|'  -e 's|__port__|'$NAMENODE_IPC_PORT'|' $HADOOP_HOME/contrib/hadoop-deployer/etc/core-site-template.xml  > $HADOOP_HOME/conf/core-site.xml

# generate mapred-site.xml
sed -e 's|__hostname__|'$MASTER_NODE'|'  -e 's|__port__|'$JOBTRACKER_IPC_PORT'|' $HADOOP_HOME/contrib/hadoop-deployer/etc/mapred-site-template.xml  > $HADOOP_HOME/conf/mapred-site.xml

