FROM centos:7

RUN yum install -y make gcc-c++ systemd ruby ruby-devel rubygem-bundler git

WORKDIR /usr/src
ENV RUBOCOP=false

COPY . .
RUN bundle install
RUN cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32 | awk '{ print $1 }' | tee /etc/machine-id
RUN bundle exec rake
