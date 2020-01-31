# Base-image
FROM ubuntu:18.04

# Configuring environment
ENV HADOOP_BASE=/opt/hadoop
ENV HADOOP_HOME=/opt/hadoop/current
ENV HADOOP_VERSION=2.8.5
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV NEW_USER=hduser

# Updating repositories
RUN apt-get update \
 && apt-get install -y \
		ssh  \
		net-tools \
		iptables \
		rsync \
		vim \
		openjdk-8-jdk \
		python3.8 \
		python3.8-venv \
		jupyter-notebook

# Getting, extracting and copying hadoop to $HADOOP_BASE
RUN wget http://mirror.nbtelecom.com.br/apache/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz \
		&& tar -xzf hadoop-$HADOOP_VERSION.tar.gz \
		&& mkdir -p $HADOOP_BASE \
		&& mv hadoop-$HADOOP_VERSION $HADOOP_BASE \
		&& cd $HADOOP_BASE \
		&& ln -s $HADOOP_BASE/hadoop-$HADOOP_VERSION current \
		&& cd \
		&& echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
		&& echo "PATH=$PATH:$HADOOP_HOME/bin" >> ~/.bashrc

# Creating the user set on $NEW_USER env var with 'home' directory
RUN useradd -m $NEW_USER

# Creating RSA key, copying to ~/.ssh and changing 
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa \
		&& cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
		&& chmod 0600 ~/.ssh/authorized_keys

# Adding hadoop conf
ADD conf/*.xml $HADOOP_HOME/etc/hadoop/ 

ADD conf/ssh_config in /home/$NEW_USER/.ssh/config 

ADD start-hadoop.sh /home/$NEW_USER/start-hadoop.sh 

EXPOSE 5000 50030 50060 50070 50075 8088 8888



RUN bash start-hadoop.sh



