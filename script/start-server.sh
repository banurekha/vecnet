#!/bin/bash

# Starts the server on the dl-vecnet server. It assumes
# there is an nginx reverse proxy at port 80

app_root=$(cd $(dirname $0)/.. && pwd)

source /etc/profile.d/chruby.sh
chruby 2.0.0-p353

source $app_root/script/get-env.sh
cd $RAILS_ROOT
bundle exec unicorn -D -E deployment -c $RAILS_ROOT/config/unicorn.rb
