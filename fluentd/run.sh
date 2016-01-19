if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
fi

mkdir -p /etc/fluent/configs.d/input/docker
mkdir -p /etc/fluent/configs.d/input/syslog

ruby generate_throttle_configs.rb

fluentd
