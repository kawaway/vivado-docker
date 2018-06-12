FROM ubuntu:16.04

MAINTAINER Colm Ryan <cryan@bbn.com>

#install dependences for:
# * downloading Vivado (wget)
# * xsim (gcc build-essential to also get make)
# * MIG tool
#     see: https://japan.xilinx.com/support/answers/67000.html
#     libglib2.0-0
#     libsm6
#     libx11-6
#     libxext6
#     libxi6
#     libxtst6
#     libxrender1
#     libxrandr2
#     libfreetype6
#     libfontconfig
#     libgtk2.0-0
#     libstdc++6
#     libqtgui4
# * CI (git)
# * volume ownership (sudo)
RUN apt-get update && apt-get install -y \
  wget \
  sudo \
  build-essential \
  libglib2.0-0 \
  libsm6 \
  libx11-6 \
  libxext6 \
  libxi6 \
  libxtst6 \
  libxrender1 \
  libxrandr2 \
  libfreetype6 \
  libfontconfig \
  libgtk2.0-0 \
  libstdc++6 \
  libqtgui4 \
  git

# copy in config file
COPY install_config.txt /

# download and run the install
ARG VIVADO_TAR_HOST
ARG VIVADO_TAR_FILE
ARG VIVADO_VERSION
RUN echo "Downloading ${VIVADO_TAR_FILE} from ${VIVADO_TAR_HOST}" && \
  wget ${VIVADO_TAR_HOST}/${VIVADO_TAR_FILE}.tar.gz -q && \
  echo "Extracting Vivado tar file" && \
  tar xzf ${VIVADO_TAR_FILE}.tar.gz && \
  /${VIVADO_TAR_FILE}/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config install_config.txt && \
  rm -rf ${VIVADO_TAR_FILE}*

RUN	apt-get install -y \
	vim \
	emacs-nox \
	zip \
	strace \
	ltrace \
	gdb \
	minicom \
	curl \
	openssh-server \
	udev

RUN	apt-get install -y \
	# for /usr/share/zoneinfo
	tzdata \
        # for locale-gen
	locales && \
	cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
	echo 'Asia/Tokyo' > /etc/timezone
RUN	echo 'LC_ALL=en_US.UTF-8' >  /etc/default/locale && \
	echo 'LANG=en_US.UTF-8' >> /etc/default/locale && \
	locale-gen en_US.UTF-8

RUN	mkdir -p /var/run/sshd

RUN	cd /opt/Xilinx/Vivado/${VIVADO_VERSION}/data/boards/board_files && \
	wget ${VIVADO_TAR_HOST}/pynq-z1.zip -q && \
	unzip pynq-z1.zip &&\
	rm -rf pynq-z1.zip

# X11 forwading failed because docker default IPv6 is link local only
# temporarry disable IPv6, I'll be enable dual-stack
RUN	echo "AddressFamily inet" >> /etc/ssh/sshd_config

RUN	apt-get install -y \
		dbus \
		dbus-x11 \
		xorg
		xserver-xorg-legacy \
		xinit \
		xterm
		usbutils \
		pciutils

#make a Vivado user
ARG	_CRED
RUN	adduser vivado && \
	echo "vivado:$_CRED" | chpasswd && \
#	echo "vivado ALL=(ALL:ALL) NOPASSWD: /bin/chown" >> /etc/sudoers && \
	echo "vivado ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
	usermod -G dialout -a vivado

ADD	entrypoint /bin
# For testing X11 forward and test sshd
#RUN	apt-get install -y x11-apps openssh-client

#add vivado tools to path
RUN	echo -n "#!/bin/sh\n[ -f /etc/environment ] && source /etc/environment" > /etc/profile.d/environment.sh && \
	cat /etc/profile.d/environment.sh && \
	echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /etc/environment && \
	echo "source /opt/Xilinx/SDK/${VIVADO_VERSION}/settings64.sh" >> /etc/environment

# Install cable drivers
RUN	cd /opt/Xilinx/Vivado/2018.1/data/xicom/cable_drivers/lin64/install_script/install_drivers && \
	./install_drivers

#copy in the license file
USER	vivado
RUN mkdir /home/vivado/.Xilinx
COPY Xilinx.lic /home/vivado/.Xilinx/
RUN	touch /home/vivado/.Xauthority
WORKDIR /home/vivado/workspace

USER	root
