# bigram-hadoop

A "bootstrap" image for pySpark developers.


## Version

0.0.7



## Introduction

This is a repository for Dockerfile and some components necessary to build an image that provides a minimal of environment to work with Hadoop and pySpark. 



## Features

* Hadoop 2.8.5
* Spark 2.4.4( Built using Maven because this combination of versions of Hadoop and Spark must be built )
* Python 3.6
* jupyter-notebook



## Requirements

* Some Linux distro( I can't tell if this works on Windows nor MacOS. Probably yes on MacOS!)

* docker 19.03.5

* Dockerfile

* 16GB of RAM

* Intel Core i5 is ok but, i7 is recommended

  

## Files, directories

```bash
.
├── conf
│   ├── config
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── mapred-site.xml
│   └── yarn-site.xml
├── Dockerfile
├── LICENSE
├── README.md
└── start-hadoop.sh

```

* conf/config: ssh configuration file

* conf/*-site.xml: hadoop basic configuration files

* Dockerfile: docker file for build the image/container

* start-hadoop.sh: script that starts Hadoop environment(zookeeper, hdfs, yarn, etc.)

  





## Getting started

First of all, **install docker!**  

* [How to install docker on Ubuntu/Mint](https://docs.docker.com/install/linux/docker-ce/ubuntu/)



Then, choose your "destiny"!





### Dockerhub way

Faster, not so fun and **probably out of date**. But works! Just run *docker pull* as at bellow:

`docker pull carneiro/bigram-hadoop`



Dockerhub image site: [carneiro/bigram-hadoop](https://hub.docker.com/repository/docker/carneiro/bigram-hadoop)



### Dockerfile way

The Dockfile is certainly updated, but is very slow to run! 



What this will do?

1. Install basic Linux image(Ubuntu18.04)
2. Install Hadoop 2.5.8 basic stack(HDFS,Yarn,HDFS, Hive etc)
3. Build Spark 2.4.4 using Maven and configure it



All stuff on [Github](https://github.com/bang/bigram-hadoop)



1. Dockerfile:

   ```dockerfile
   FROM ubuntu:18.04
   
   # set environment vars
   ENV HADOOP_BASE /opt/hadoop
   ENV HADOOP_HOME /opt/hadoop/current
   ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
   ENV SPARK_BASE /opt/spark
   ENV SPARK_HOME /opt/spark/current
   # install packages
   RUN \
     apt-get update && apt-get install -y \
     curl \
     ssh \
     rsync \
     vim \
     openjdk-8-jdk \
     maven
   
   
   # download and extract hadoop, set JAVA_HOME in hadoop-env.sh, update path
   RUN curl -L \
   	--progress-bar 'http://mirror.nbtelecom.com.br/apache/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz' \
   		-o "hadoop-2.8.5.tar.gz" 
   ENV HADOOP_VERSION=2.8.5
   RUN mkdir -p $HADOOP_BASE && tar -xzf hadoop-$HADOOP_VERSION.tar.gz -C $HADOOP_BASE \
   	&& cd $HADOOP_BASE \
   	&& ln -s hadoop-$HADOOP_VERSION current \
   	&& cd / \
   	&& echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
   	&& echo "PATH=$PATH:$HADOOP_HOME/bin" >> ~/.bashrc
   
   # create ssh keys
   RUN  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa 
   RUN  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 
   RUN  chmod 0600 ~/.ssh/authorized_keys
   
   # copy hadoop configs
   ADD conf/*xml $HADOOP_HOME/etc/hadoop/
   
   # copy ssh config
   ADD conf/config /root/.ssh/config
   
   # copy script to start hadoop
   # ADD start-hadoop.sh /start-hadoop.sh
   # CMD bash start-hadoop.sh
   
   # create hduser user
   RUN useradd -m hduser
   RUN groupadd hdfs
   RUN usermod -aG hdfs hduser
   RUN mkdir ~hduser/.ssh
   
   # create ssh keys
   RUN  ssh-keygen -t rsa -P '' -f ~hduser/.ssh/id_rsa 
   RUN  cat ~/.ssh/id_rsa.pub >> ~hduser/.ssh/authorized_keys 
   RUN  chmod 0600 ~hduser/.ssh/authorized_keys
   
   # download and build spark with maven with Hive and hive-trhift support 
   ENV MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
   RUN curl -L \
   	--progress-bar 'http://mirror.nbtelecom.com.br/apache/spark/spark-2.4.4/spark-2.4.4.tgz' \
   		-o "spark-2.4.4.tgz"
   ENV SPARK_VERSION=2.4.4
   ENV SPARK_PART_VERSION=2.4
   ENV HADOOP_PART_VERSION=2.8
   RUN mkdir -p $SPARK_BASE && tar -xvf spark-$SPARK_VERSION.tgz
   RUN cd spark-$SPARK_VERSION \
   	&& ./build/mvn \
    	-Pyarn -Phadoop-$HADOOP_PART_VERSION -Dhadoop.version=$HADOOP_VERSION \
    	-Phive -Phive-thriftserver \
    	-DskipTests clean package
   
   # Moving Spark built to the base directory and configurating over /opt dir
   RUN mv spark-$SPARK_VERSION $SPARK_BASE
   RUN	cd $SPARK_BASE \
    	&& ln -s spark-$SPARK_VERSION current \
    	&& cd / 
   
   # Configuring ~hduser/.bashrc
   RUN	echo "export JAVA_HOME=$JAVA_HOME" >> ~hduser/.bashrc \
   	&& echo "export HADOOP_HOME=$HADOOP_HOME" >> ~hduser/.bashrc \
   	&& echo "alias python='python3.6'" >> ~hduser/.bashrc \
   	&& echo "export PYSPARK_PYTHON='python3.6'" >> ~hduser/.bashrc \
   	&& echo "export SPARK_HOME=$SPARK_HOME" >> ~hduser/.bashrc \
   	&& echo "export SPARK_MAJOR_VERSION=2" >> ~hduser/.bashrc \
   	&& echo "export PATH=$PATH:$HADOOP_HOME/bin:$SPARK_HOME/bin" >> ~hduser/.bashrc
   
   # expose various ports
   # EXPOSE 8088 50070 50075 50030 50060
   
   
   ```

   

2. Building the image

   `docker build -t bigram-hadoop .`

   

3. Creating the container

   ```bash
   docker run  \
   --network host \
   --cpus=".5" \
   --memory="8g" \
   --name bigram-hadoop-container \
   -d bigram-hadoop
   ```

   


   * **--network host**: A simple explanation is that container will inherit IP and expose all ports. **Never use this way in production! Just for developing in YOUR machine!**

   * **--cpus**=".5": enable 50% of CPUs for the container

   * **--memory**="8g": allocate max 8GB for the container

   * **--name**: sets a name for the container

   * **-d**: container on background

   * **bigram-hadoop**: name of the image

     


3. Accessing the container

   `docker exec -it --privileged bigram-hadoop-container bash`

   if doesn't work, try:

   `docker run -it --rm bigram-hadoop`

   

5. create user project home in HDFS

   `hdfs dfs -mkdir -p /user/hduser`

   

6. Grant permissions on HDFS home dir

   `hdfs dfs -chown hduser /user/hduser`

   

7. Change user to $NEW_USER(default = 'hduser')

   `su - hduser`

   

8. Create a new jupyter notebook

   `jupyter-notebook`

   

9. Place this code at below and try to run it!

   ```python
   import pyspark
   import pyspark.sql.functions as F
   from pyspark.sql import SparkSession
   from pyspark.sql.types import *
   
   # start session
   spark = SparkSession.builder.appName('test').enableHiveSupport().getOrCreate()
   
   # Setting some data
   data = [["Spark","is","awsome!"]]
   
   # Declaring schema
   schema = StructType(fields = [
       StructField("col1",StringType(),True)
       ,StructField("col2",StringType(),True)
       ,StructField("col3",StringType(),True)
   ])
   
   # Getting a dataframe from all of this
   df = spark.createDataFrame(data,schema)
   
   ```

   ## 
   
   

