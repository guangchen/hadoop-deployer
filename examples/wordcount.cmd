#!/bin/sh

#PBS -k o
#PBS -l nodes=8:ppn=8,walltime=01:00:00
#PBS -M XXXX@umail.iu.edu
#PBS -m abe
#PBS -N hadoop_wordcount
#PBS -j oe
#PBS -V

# This is an example of PBS script used on IU Quarry cluster to deploy hadoop cluster

# move to my $SCRATCH directory
SCRATCH="/N/u/$USER/Quarry"
cd $SCRATCH

# copy JDK lib to $SCRATCH
DIRNAME="jdk1.6.0_38"
if [ ! -d $DIRNAME ];
then
        echo "$DIRNAME doesn't exist, copy it from $HOME/$DIRNAME"
        cp -r $HOME/$DIRNAME .
fi

# copy hadoop to $SCRATCH
DIRNAME="hadoop-1.0.4"
if [ ! -d $DIRNAME ];
then
        echo "$DIRNAME doesn't exist, copy it from $HOME/$DIRNAME"
        cp -r $HOME/$DIRNAME .
fi

MASTER_NODE=`sort -u $PBS_NODEFILE | head -n 1`

HADOOP_HOME="$SCRATCH/hadoop-1.0.4"

# configure hadoop cluster
ssh $MASTER_NODE "$HADOOP_HOME/contrib/hadoop-deployer/bin/configure_hadoop_cluster.sh $PBS_NODEFILE"

# format namenode
ssh $MASTER_NODE "$HADOOP_HOME/bin/hadoop namenode -format"

# start hadoop cluster
ssh $MASTER_NODE "$HADOOP_HOME/bin/start-all.sh"

echo "hadoop cluster starts up"

# sleep 120 seconds to make sure all daemons are up
sleep 120

#### Run your jobs here

cd $HOME/hadoop-wc

corpus_folder="public-corpus"

full_path="/N/dc/scratch/$USER/data-corpus/$corpus_folder"

PATH_PREFIX="$HOME/hadoop-wc"
JAR_NAME="hadoop-wordcount-0.0.1.jar"

JAR_NAME="$PATH_PREFIX/build/jar/$JAR_NAME"

MAIN_CLASS_NAME="edu.indiana.d2i.htrc.wc.HadoopWCDriver"

ENG_DICT_NAME="english_words"
ENG_DICT_PATH="$PATH_PREFIX/resources/$ENG_DICT_NAME"

ENG_STOPWORDS_NAME="english_stop"
ENG_STOPWORDS_PATH="$PATH_PREFIX/resources/$ENG_STOPWORDS_NAME"

FILES="$ENG_DICT_PATH,$ENG_STOPWORDS_PATH"
LIBJARS="$PATH_PREFIX/lib/commons-logging-1.1.1.jar"

INPUT_DIR="htrc-wc/$corpus_folder"
OUTPUT_DIR="htrc-wc/wc-output"

CONFIG_FILE_NAME="configuration.properties"
CONFIG_FILE_PATH="$PATH_PREFIX/conf/$CONFIG_FILE_NAME"

# make directory in HDFS
$HADOOP_HOME/bin/hadoop dfs -mkdir htrc-wc

# copy corpus data in local fs to hdfs
$HADOOP_HOME/bin/hadoop dfs -copyFromLocal $full_path htrc-wc

$HADOOP_HOME/bin/hadoop jar $JAR_NAME $MAIN_CLASS_NAME -D mapred.reduce.tasks=40 -files $FILES -libjars $LIBJARS $INPUT_DIR $OUTPUT_DIR $CONFIG_FILE_PATH

# remove directory if it already exists
rm -rf $HOME/wc-result/wc-output

$HADOOP_HOME/bin/hadoop dfs -copyToLocal htrc-wc/wc-output $HOME/wc-result

echo

# stop hadoop cluster
ssh $MASTER_NODE "$HADOOP_HOME/bin/stop-all.sh"

# sleep 60 seconds to make sure all daemons are down
sleep 60

# clean up
$HADOOP_HOME/contrib/hadoop-deployer/bin/clean_machines.sh $MASTER_NODE $HADOOP_HOME/conf/slaves
