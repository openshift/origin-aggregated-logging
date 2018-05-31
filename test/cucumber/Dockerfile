FROM fedora:27

ENV LOGLEVEL=debug \
    LOGFILE=/opt/app/src/log/logging-cucumber.log \
    KUBECONFIG=/tmp/.kube/config/test.kubeconfig \
    OC_URL=https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz \
    BROWSER_DRIVER_GECKO=https://github.com/mozilla/geckodriver/releases/download/v0.20.1/geckodriver-v0.20.1-linux64.tar.gz \
    INSTALL_PACKAGES="ruby ruby-devel make firefox xorg-x11-server-Xvfb redhat-rpm-config wget gcc bzip2" \
    HOME=/opt/app/src \
    HEADLESS=true

ADD Gemfile* "${HOME}/"

RUN dnf install -y --setopt=tsflags=nodocs $INSTALL_PACKAGES

WORKDIR /usr/local/bin
RUN wget -q -O client.tar.gz $OC_URL && \
      tar -xf client.tar.gz --strip=1 && \
      rm client.tar.gz && \
      wget -q -O gecko.tar.gz $BROWSER_DRIVER_GECKO && \
      tar -xf gecko.tar.gz && \
      rm gecko.tar.gz && \
    gem install bundler --no-ri --no-rdoc

WORKDIR ${HOME}
RUN mkdir -m 777 log && \
    GEM_HOME=vendor bundle install 

RUN chmod -R 755 .
ADD run.sh .
ADD lib ./lib
ADD features ./features/

WORKDIR ${HOME}
ENTRYPOINT ["/opt/app/src/run.sh"]
