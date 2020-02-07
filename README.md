# bigram-hadoop

A "bootstrap" image for pySpark developers.


## Version

0.0.8



## Introduction

This is a repository for Dockerfile and some components necessary to build an image that provides a minimal of environment to work with Hadoop and pySpark. 



## Features

* Hadoop 2.8.5(Mapreduce + YARN + HDFS)
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
   
   # configuring tz to avoid problems with interaction problems with tzdata package
   ENV TZ=America/Sao_Paulo 
   RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
   
   # Install packages
   RUN \
     apt-get update && apt-get install -y \
     net-tools \
     sudo \
     curl \
     ssh \
     rsync \
     vim \
     openjdk-8-jdk \
     maven \
     python3-pip \
     jupyter-notebook
   
   
   # download and extract hadoop, set JAVA_HOME in hadoop-env.sh, update path
   #RUN curl -L \
   #	--progress-bar 'https://www-us.apache.org/dist/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz' \
   #		-o "hadoop-2.8.5.tar.gz" 
   ENV HADOOP_VERSION=2.8.5
   COPY hadoop-$HADOOP_VERSION.tar.gz .
   RUN mkdir -p $HADOOP_BASE \
   	&& tar -xzvmf hadoop-$HADOOP_VERSION.tar.gz -C $HADOOP_BASE/ \
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
   COPY conf/*xml $HADOOP_HOME/etc/hadoop/
   
   # copy ssh config
   COPY conf/config /root/.ssh/config
   
   # create hduser user
   RUN useradd -m -s /bin/bash hduser \
    	&& groupadd hdfs \
    	&& usermod -aG hdfs hduser \
    	&& usermod -aG sudo hduser \
    	&& mkdir ~hduser/.ssh
   
   # create ssh keys
   RUN  ssh-keygen -t rsa -P '' -f ~hduser/.ssh/id_rsa \
    	&&  cat ~/.ssh/id_rsa.pub >> ~hduser/.ssh/authorized_keys \
    	&&  chmod 0600 ~hduser/.ssh/authorized_keys
   
   # download and build spark with maven with Hive and hive-trhift support 
   ENV MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
   # RUN curl -L \
   # # 	--progress-bar 'https://www-us.apache.org/dist/spark/spark-2.4.4/spark-2.4.4.tgz' \
   # # 		-o "spark-2.4.4.tgz"
   
   ENV SPARK_VERSION=2.4.4
   
   COPY spark-$SPARK_VERSION.tgz .
   ENV SPARK_PART_VERSION=2.4
   ENV HADOOP_PART_VERSION=2.8
   
   RUN mkdir -p $SPARK_BASE && tar -xzmvf spark-$SPARK_VERSION.tgz \
    	&& cd spark-$SPARK_VERSION \
    	&& ./build/mvn \
     	-Pyarn -Phadoop-$HADOOP_PART_VERSION -Dhadoop.version=$HADOOP_VERSION \
     	-Phive -Phive-thriftserver \
     	-DskipTests clean package 
   
   # Moving Spark after build dirs to $SPARK_HOME proving to be IMPOSSIBLE!
   # ENV SPARK_VERSION=2.4.4
   # ENV SPARK_BASE=/opt/spark
   # ENV SPARK_HOME=$SPARK_BASE/current
   RUN cd /
   RUN tar -cBpvzf spark-$SPARK_VERSION.tar.gz spark-$SPARK_VERSION
   #RUN rm -f spark-$SPARK_BASE/$SPARK_VERSION 
   RUN tar -xzvmf spark-$SPARK_VERSION.tar.gz -C $SPARK_BASE/
   RUN ln -s spark-$SPARK_VERSION $SPARK_HOME \
     	&& cd / 
   
   # Install pyspark
   RUN pip3 install pyspark
   
   # Configuring ~hduser/.bashrc
   RUN	echo "export JAVA_HOME=$JAVA_HOME" >> ~hduser/.bashrc \
    	&& echo "export HADOOP_HOME=$HADOOP_HOME" >> ~hduser/.bashrc \
    	&& echo "alias python='python3.6'" >> ~hduser/.bashrc \
    	&& echo "alias pip='pip3'" >> ~hduser/.bashrc \
    	&& echo "export PYSPARK_PYTHON='python3.6'" >> ~hduser/.bashrc \
    	&& echo "export SPARK_HOME=$SPARK_HOME" >> ~hduser/.bashrc \
    	&& echo "export SPARK_MAJOR_VERSION=2" >> ~hduser/.bashrc \
    	&& echo "export PATH=$PATH:$HADOOP_HOME/bin:$SPARK_HOME/bin" >> ~hduser/.bashrc
   
   # copy script to start hadoop
   COPY start-hadoop.sh /start-hadoop.sh
   RUN bash start-hadoop.sh &
   
   # Preparing HDFS for hduser
   RUN $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hduser
   RUN $HADOOP_HOME/bin/hdfs dfs -chown hduser /user/hduser
   
   # Cleanup
   RUN rm -f *.tar.gz *.tgz *.sh 
   
   # RUNNING jupyter-notebook
   # as hduser ??????
   
   
   # expose various ports
   EXPOSE 8088 8888 5000 50070 50075 50030 50060
   
   
   
   
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

     


3. Running the container

   `docker run --network host --user -p8888 -p8088  hduser -it  bigram-hadoop-container jupyter-notebook`

   

   You'll see something like this:

   ```bash
   WARNING: Published ports are discarded when using host network mode                                              
   [I 15:36:47.100 NotebookApp] Writing notebook server cookie secret to /home/hduser/.local/share/jupyter/runtime/notebook_cookie_secret
   [I 15:36:47.277 NotebookApp] Serving notebooks from local directory: /                                           
   [I 15:36:47.277 NotebookApp] 0 active kernels                                                                    
   [I 15:36:47.277 NotebookApp] The Jupyter Notebook is running at:                                                 
   [I 15:36:47.277 NotebookApp] http://localhost:8888/?token=d940ac2eff1330843681bb360ffec84f604a3c43643723a1       
   [I 15:36:47.277 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
   [W 15:36:47.277 NotebookApp] No web browser found: could not locate runnable browser.                            
   [C 15:36:47.277 NotebookApp]                                                                                     
                                                                                                                    
       Copy/paste this URL into your browser when you connect for the first time,                                   
       to login with a token:                                                                                      
           http://localhost:8888/?token=d940ac2eff1330843681bb360ffec84f604a3c43643723a1
   ```

   

   Now, copy the 'http' address, create a new Python3 notebook and place this code at below and try to run it!

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

   

