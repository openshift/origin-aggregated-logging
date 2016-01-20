#!/bin/bash

# this will parse out the retention settings, combine like settings, create cron line definitions for them with curator, run the jobs immediately, then run the jobs again every CURATOR_CRON_HOUR and CURATOR_CRON_MINUTE (by default, every midnight)
python -u run_cron.py
