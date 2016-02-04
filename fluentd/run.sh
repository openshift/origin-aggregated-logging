if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
fi

# Example format below
#THROTTLE_SETTINGS='{"project1":{"options":[{"disable_retry_limit":"true","retry_wait":"10s"},{"buffer_queue_limit":"64"}]},"project2":{"options":[{"flush_interval":"10s"},{"retry":"1m"}]}}'

ruby generate_throttle_configs.rb "$THROTTLE_SETTINGS"

fluentd
