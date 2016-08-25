FROM sequenceiq/hadoop-docker:2.7.1
MAINTAINER Kevin Liew

# Git, Maven
RUN yum install -y git
RUN curl -s https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz | \
    tar -xz -C /usr/local/ && \
    cd /usr/local && \
    ln -s apache-maven-3.3.9 maven
ENV M2_HOME=/usr/local/maven
ENV PATH=${M2_HOME}/bin:${PATH}
ENV MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=256m -XX:+CMSClassUnloadingEnabled -Dmaven.artifact.threads=1000 "

# http://www.apache.org/mirrors/dist.html
ARG APACHE_MIRROR=http://apache.cs.utah.edu

# Zookeeper
ARG ZOOKEEPER_VERSION=3.4.8
RUN curl -s $APACHE_MIRROR/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./zookeeper-$ZOOKEEPER_VERSION zookeeper
ENV ZOO_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOO_HOME/bin
RUN mv $ZOO_HOME/conf/zoo_sample.cfg $ZOO_HOME/conf/zoo.cfg
RUN mkdir /tmp/zookeeper

# HBase
ARG HBASE_MAJORMINOR=1.1
ARG HBASE_PATCH=5
RUN curl -s $APACHE_MIRROR/hbase/$HBASE_MAJORMINOR.$HBASE_PATCH/hbase-$HBASE_MAJORMINOR.$HBASE_PATCH-bin.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hbase-$HBASE_MAJORMINOR.$HBASE_PATCH hbase
ENV HBASE_HOME /usr/local/hbase
ENV PATH $PATH:$HBASE_HOME/bin

# Phoenix
# Cache download of repo and dependencies and unmodified modules
ARG REPO=https://github.com/apache/phoenix
RUN git clone $REPO
WORKDIR phoenix
RUN mvn -T 1000C clean install -DskipTests
# Update and install
ARG REVISION=master
RUN git pull && git checkout $REVISION
RUN mvn package -DskipTests
RUN for file in /phoenix/phoenix-assembly/target/phoenix-*SNAPSHOT.tar.gz; do tar xf $file -C /usr/local; done
RUN ln -s /usr/local/phoenix-* /usr/local/phoenix
ENV PHOENIX_HOME /usr/local/phoenix
ENV PATH $PATH:$PHOENIX_HOME/bin
RUN ln -s $PHOENIX_HOME/phoenix-*-server.jar $HBASE_HOME/lib/phoenix-server.jar
WORKDIR /

# HBase and Phoenix configuration files
ADD hbase-site.xml $HBASE_HOME/conf/hbase-site.xml

# Zookeeper port
EXPOSE 2181

# Phoenix queryserver port
EXPOSE 8765

ENV PHOENIX_QUERYSERVER_OPTS "-Xdebug -agentlib:jdwp=transport=dt_socket,address=9999,server=y,suspend=n"

CMD $HADOOP_HDFS_HOME/sbin/start-dfs.sh && \
    start-hbase.sh && \
    queryserver.py start

