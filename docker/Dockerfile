FROM centos:7
MAINTAINER Alan Denniston <alan.denniston@gmail.com>

RUN yum update -y --nogpgcheck && yum install -y --nogpgcheck \
  gmp \
  libidn \ 
  wget \
  nano \
  make \
  nc \
  sudo \
  sysstat \
  libtool-ltdl \
  glibc \
  perl \
  ntp \
  libaio \
  unzip \
  perl-core \
  net-tools \
  perl \
  perl-core \
  screen \
  w3m \
  bind-utils \
  nmap \
  sed \
  sysstat \
  libaio \
  rsync \
  telnet \
  aspell \
  vim \
  openssh \
  openssh-server \
  rsyslog \
  && yum clean all \
  && yum clean metadata
  VOLUME ["/opt/zimbra"]

EXPOSE 22 25 465 587 110 143 993 995 80 443 8080 8443 7071 514

COPY opt /opt/

CMD ["/bin/bash", "/opt/start.sh", "-bash"]
