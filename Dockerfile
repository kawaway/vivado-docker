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
#make a Vivado user
RUN adduser --disabled-password --gecos '' vivado
USER vivado
WORKDIR /home/vivado
#add vivado tools to path
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/vivado/.bashrc

#copy in the license file
RUN mkdir /home/vivado/.Xilinx
COPY Xilinx.lic /home/vivado/.Xilinx/
