FROM ubuntu:18.04

# set environment vars
ENV HADOOP_BASE /opt/hadoop
ENV HADOOP_HOME /opt/hadoop/current
ENV HADOOP_VERSION=2.8.5
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV SPARK_BASE /opt/spark
ENV SPARK_HOME /opt/spark/current
ENV SPARK_VERSION=2.4.4

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
RUN curl -L \
	--progress-bar 'https://www-us.apache.org/dist/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz' \
		-o "hadoop-$HADOOP_VERSION.tar.gz" 

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
RUN curl -L \
	--progress-bar 'https://www-us.apache.org/dist/spark/spark-2.4.4/spark-2.4.4.tgz' \
		-o "spark-$SPARK_VERSION.tgz"

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
RUN cd /
RUN tar -cBpvzf spark-$SPARK_VERSION.tar.gz spark-$SPARK_VERSION
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

# expose various ports
EXPOSE 8088 8888 5000 50070 50075 50030 50060

