FROM ubuntu:16.04

RUN apt-get update -q && apt-get install -qy --no-install-recommends \
        build-essential \
        ruby \
        ruby-bundler \
        ruby-dev \
        libsystemd0 \
        git \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* \
      && truncate -s 0 /var/log/*log

WORKDIR /usr/src

COPY . .
RUN bundle install
RUN cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32 | awk '{ print $1 }' | tee /etc/machine-id
RUN bundle exec rake
