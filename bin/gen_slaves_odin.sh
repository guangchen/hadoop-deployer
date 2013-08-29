#! /bin/sh

if [ $# != 2 ]; then
        echo "Script Usage: ./gen_machines.sh <start odin node number> <end odin node number>"
        exit
fi

FNAME="slaves"

if [ -f $FNAME ];
then
        #echo "File $FNAME already exists, delete it first"
        rm $FNAME
fi

for ((i = $1; i <= $2; i++))
do
        printf "odin%03d\n" $i >> $FNAME
done

