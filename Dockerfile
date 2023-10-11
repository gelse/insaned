# get the build image
FROM debian:12-slim as insaned-build
ENV APP_DIR=/app
ENV PACKAGE_DIR=/deploy
WORKDIR "$APP_DIR"

# update system and install dependencies
RUN apt-get update \
&& apt-get upgrade -y
RUN apt-get install -y \
  libsane-dev \
  git \
  build-essential \
  debhelper \
  libjq1 \
  curl \
  jq

# clone the repo
#RUN git clone https://github.com/gelse/insaned.git
COPY . $APP_DIR/insaned/

# build the package
RUN cd $APP_DIR/insaned \
  && make debian 

# get the hosting image
FROM debian:12-slim as insaned

ENV APP_DIR=/app
WORKDIR "$APP_DIR"

# copy package from build image
COPY --from=insaned-build "$APP_DIR/*.deb" "$APP_DIR/"

# update system and install dependencies (and cleanup)
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    libjq1 \
    curl \
    jq \
    libsane \
    libsane1 \
  && rm -rf /var/lib/apt/lists/* \
  && dpkg -i insaned_*.deb \
  && chmod +x /etc/insaned/events/* \
  && chmod +x /etc/insaned/events/user/* \
  && rm *.deb \
  && echo "install finished"
COPY config.env /etc/insaned/events/.env
VOLUME /etc/insaned/events/user

# declare entry point / starting program
ENTRYPOINT ["insaned", "--dont-fork"]

# add default parameters
CMD ["-v"]

