#! /bin/bash

##############################################################
# move-spark-dirs 											 #
#															 #
# Usage: /bin/bash move-spark-dirs. 						 #
# 															 #
# Description: Moves all spark built dirs on spark-m.n.r to  #
# 			   directories defined by $SPARK_BASE. The       #
# 			   variables $SPARK_HOME and $SPARK_VERSION and  #
# 			   $SPARK_HOME. Both must be previously defined  #
#															 #
#															 # 
#															 #
##############################################################


# Checking SPARK_VERSION and SPARK_HOME vars
if [ -z "$SPARK_VERSION" ]; then
	echo "SPARK_VERSION is not defined! Please export it!"
	exit 1
fi

if [ -z "$SPARK_HOME" ]; then
	echo "SPARK_HOME is not defined! Please export it!"
	exit 1
fi

# Declaring and defining dirs array
declare -a DIRS
DIRS=(R bin conf data examples graphx launcher mllib-local python resource-managers sql target assembly common core dev external hadoop-cloud mllib project repl sbin streamin tools)

# moving dirs
for i in "${DIRS[@]}"
do
	echo "Moving '/spark-$SPARK_VERSION/$i' to '$SPARK_HOME/'"
	mv /spark-$SPARK_VERSION/$i $SPARK_HOME/
done

exit 0
