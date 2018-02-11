###################################### >Last Modified on Sun, 11 Feb 2018< 
# docker image for spark
# 
# 
# create docker image from Dockerfile:
# docker build . -t stdiff/suse

FROM opensuse:42.2

ARG hadoop_tar=http://apache.mirror.iphh.net/hadoop/common/hadoop-2.6.5/hadoop-2.6.5.tar.gz

RUN mkdir /workspace
WORKDIR /workspace

############################################################# utilities
RUN zypper --non-interactive install vim
RUN zypper --non-interactive install wget
RUN zypper --non-interactive install curl
RUN zypper --non-interactive install tar
RUN zypper --non-interactive install which

################################################################# ssh/d
RUN zypper --non-interactive install openssh

RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
RUN ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

COPY conf/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2222" >> /etc/ssh/sshd_config
RUN /usr/sbin/sshd -p 2222

############################################################ Ocale Java 
COPY jdk-8u131-linux-x64.rpm jdk-8u131-linux-x64.rpm
RUN rpm -iv jdk-8u131-linux-x64.rpm

ENV JAVA_HOME /usr/java/latest
ENV PATH $PATH:$JAVA_HOME/bin

################################################################ Hadoop 
RUN wget $hadoop_tar
RUN tar xvfz hadoop-2.6.5.tar.gz
RUN mv hadoop-2.6.5 /usr/local/hadoop

ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV YARN_HOME $HADOOP_HOME 
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/lib/native 
ENV HADOOP_INSTALL $HADOOP_HOME 
ENV PATH $PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin 

RUN cd $HADOOP_HOME/etc/hadoop
COPY conf/core-site.xml core-site.xml
COPY conf/hdfs-site.xml hdfs-site.xml
COPY conf/mapred-site.xml mapred-site.xml
RUN echo 'export HADOOP_SSH_OPTS="-p 2222"' >> hadoop-env.sh

RUN $HADOOP_HOME/bin/hdfs namenode -format
RUN start-dfs.sh
RUN start-yarn.sh

RUN hadoop fs -mkdir -p /user/root

##EXPOSE 50070 50030

############################################################### Python 2
RUN zypper --non-interactive install gcc
RUN zypper --non-interactive install python
RUN zypper --non-interactive install python-devel
RUN zypper --non-interactive install python-pip
RUN pip install --upgrade pip

COPY conf/python_requirements.txt python_requirements.txt
RUN pip install -r python_requirements.txt

## Apache Spark 



