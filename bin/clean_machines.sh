#! /bin/sh

if [ $# != 2 ]; then
        echo "Script Usage: ./clean_machines.sh <master id address> </path/to/slave/nodes/file>"
        exit
fi

TMPDIR=/scratch/$USER

# clean up worker nodes
for line in `cat $2`;do
        echo "Remove $TMPDIR, /tmp/$USER, /tmp/hadoop-$USER /tmp/Jetty* /tmp/hsperfdata_$USER on $line"
        ssh $line "rm -rf $TMPDIR ; rm -rf /tmp/$USER;  rm -rf /tmp/hadoop-$USER; rm -rf /tmp/Jetty* ; rm -rf /tmp/hsperfdata_$USER"
done

# clean up master node
echo "Remove $TMPDIR, /tmp/$USER, /tmp/hadoop-$USER /tmp/Jetty* /tmp/hsperfdata_$USER on $1"
ssh $1 "rm -rf $TMPDIR ; rm -rf /tmp/$USER;  rm -rf /tmp/hadoop-$USER; rm -rf /tmp/Jetty* ; rm -rf /tmp/hsperfdata_$USER"

