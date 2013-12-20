# List all tasks from RAILS_ROOT using: cap -T
#
# NOTE: The SCM command expects to be at the same path on both the local and
# remote machines. The default git path is: '/shared/git/bin/git'.

set :bundle_roles, [:app, :work]
set :bundle_flags, "--deployment"
require 'bundler/capistrano'
# see http://gembundler.com/v1.3/deploying.html
# copied from https://github.com/carlhuda/bundler/blob/master/lib/bundler/deployment.rb
#
# Install the current Bundler environment. By default, gems will be \
#  installed to the shared/bundle path. Gems in the development and \
#  test group will not be installed. The install command is executed \
#  with the --deployment and --quiet flags. If the bundle cmd cannot \
#  be found then you can override the bundle_cmd variable to specifiy \
#  which one it should use. The base path to the app is fetched from \
#  the :latest_release variable. Set it for custom deploy layouts.
#
#  You can override any of these defaults by setting the variables shown below.
#
#  N.B. bundle_roles must be defined before you require 'bundler/#{context_name}' \
#  in your deploy.rb file.
#
#    set :bundle_gemfile,  "Gemfile"
#    set :bundle_dir,      File.join(fetch(:shared_path), 'bundle')
#    set :bundle_flags,    "--deployment --quiet"
#    set :bundle_without,  [:development, :test]
#    set :bundle_cmd,      "bundle" # e.g. "/opt/ruby/bin/bundle"
#    set :bundle_roles,    #{role_default} # e.g. [:app, :batch]

#############################################################
#  Settings
#############################################################

default_run_options[:pty] = true
set :use_sudo, false
ssh_options[:paranoid] = false
set :default_shell, '/bin/bash'

#############################################################
#  SCM
#############################################################

set :scm, :git
set :deploy_via, :remote_cache
set :scm_command, '/usr/bin/git'

#############################################################
#  Environment
#############################################################

namespace :env do
  desc "Set command paths"
  task :set_paths do
    set :ruby,      File.join(ruby_bin, 'ruby')
    #set :bundler,   File.join(ruby_bin, 'bundle')
    #set :bundler,   'bundle'
    set :rake,      "#{bundle_cmd} exec rake"
  end
end

# we are using chruby on the deploment machine
# code from https://github.com/postmodern/chruby/wiki/Capistrano
set :ruby_version, "2.0.0-p353"
set :chruby_config, "/etc/profile.d/chruby.sh"
set :set_ruby_cmd, "source #{chruby_config} && chruby #{ruby_version}"
set(:bundle_cmd) {
  "#{set_ruby_cmd} && exec bundle"
}

#############################################################
#  Passenger
#############################################################

desc "Restart Application"
task :restart_unicorn, :roles => :app do
  run "#{current_path}/script/reload-unicorn.sh"
end

#############################################################
#  Database
#############################################################

namespace :db do
  desc "Run the seed rake task."
  task :seed, :roles => :app do
    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} db:seed"
  end
end

#############################################################
#  Deploy
#############################################################

namespace :deploy do
  desc "Execute various commands on the remote environment"
  task :debug, :roles => [:app, :work] do
    run "/usr/bin/env", :pty => false, :shell => '/bin/bash'
    run "whoami"
    run "pwd"
    run "echo $PATH"
    run "which ruby"
    run "ruby --version"
    run "which rake"
    run "rake --version"
    run "which bundle"
    run "bundle --version"
  end

  desc "Start application"
  task :start, :roles => :app do
    restart_unicorn
  end

  desc "Restart application"
  task :restart, :roles => :app do
    restart_unicorn
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  # XXX: remove in favor of the default capistrano task?
  desc "Run the migrate rake task."
  task :migrate, :roles => :app do
    run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} db:migrate"
  end

  desc "Precompile assets"
  task :precompile, :roles => :app do
    run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} RAILS_GROUPS=assets assets:precompile"
  end

  desc "Link assets for current deploy to the shared location"
  task :symlink_update do
    (shared_directories + shared_files).each do |link|
      run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
    end
  end
end

# this code doesn't work quite right, but it is the way to do it.
# from http://stackoverflow.com/questions/4648180/keep-unversioned-files-when-deploying-with-capistrano
# TODO: fix
#before "deploy:setup" do
#  symlinks.setup
#end
#
#before "deploy:symlink" do
#  symlinks.update
#end

#namespace :worker do
#  task :start, :roles => :work do
#    target_file = "/home/Vecnet/resque-pool-info"
#    run [
#      "echo \"RESQUE_POOL_ROOT=$(pwd)/current\" > #{target_file}",
#      "echo \"RESQUE_POOL_ENV=#{fetch(:rails_env)}\" >> #{target_file}",
#      "sudo /sbin/service resque-poold restart"
#    ].join(" && ")
#  end
#end

namespace :vecnet do
  desc "Restart the workers on the target machine"
  task :restart_workers, :roles => :work do
    run [
      "#{current_path}/script/stop-pool.sh",
      "#{current_path}/script/start-pool.sh"
    ].join(" && ")
  end

  desc "Write the current environment values to file on targets"
  task :write_env_vars do
    run [
      "echo RAILS_ENV=#{rails_env} > #{release_path}/env-vars",
      "echo RAILS_ROOT=#{current_path} >> #{release_path}/env-vars"
    ].join(" && ")
  end
end

namespace :und do
  task :write_build_identifier, :roles => :app do
    run "cd #{release_path} && echo '#{build_identifier}' > config/bundle-identifier.txt"
  end
end

#############################################################
#  Callbacks
#############################################################

before 'deploy', 'env:set_paths'

#############################################################
#  Configuration
#############################################################

set :application, 'vecnet-dl'
set :repository,  "git://github.com/banurekha/vecnet.git"
set :build_identifier, Time.now.strftime("%Y-%m-%d %H:%M:%S")

#############################################################
#  Environments
#############################################################

desc "Setup for the QA environment"
task :qa do
  set :shared_directories, %w(log data)
  set :shared_files, %w(config/database.yml config/fedora.yml config/solr.yml config/redis.yml config/pubtkt-qa.pem)
  set :branch,      fetch(:branch, 'master')
  set :rails_env,   'qa'
  set :deploy_to,   '/home/app/vecnet'
  set :ruby_bin,    '/opt/rubies/2.0.0-p353/bin'

  set :user,        'app'
  set :domain,      'dl-vecnet-qa.crc.nd.edu'
  set :without_bundle_environments, 'headless development test'

  default_environment['PATH'] = "#{ruby_bin}:$PATH"
  server "#{user}@#{domain}", :app, :web, :db, :work, :primary => true

  after 'deploy:update_code', 'und:write_build_identifier', 'deploy:symlink_update', 'deploy:migrate', 'deploy:precompile'
  after 'deploy:update_code', 'vecnet:write_env_vars'
  after 'deploy', 'deploy:cleanup'
  after 'deploy', 'deploy:restart'
  after 'deploy', 'vecnet:restart_workers'
end

desc "Setup for the Production environment"
task :production do
  set :shared_directories, %w(log data)
  set :shared_files, %w(config/database.yml config/fedora.yml config/solr.yml config/redis.yml config/pubtkt-qa.pem)
  set :branch,      fetch(:branch, 'master')
  set :rails_env,   'production'
  set :deploy_to,   '/home/app/vecnet'
  set :ruby_bin,    '/opt/rubies/2.0.0-p353/bin'

  set :user,        'app'
  set :domain,      'dl-vecnet.crc.nd.edu'
  set :without_bundle_environments, 'headless development test'

  default_environment['PATH'] = "#{ruby_bin}:$PATH"
  server "#{user}@#{domain}", :app, :web, :db, :primary => true
  server "#{user}@dl-vecnet-w1.crc.nd.edu", :work

  after 'deploy:update_code', 'und:write_build_identifier', 'deploy:symlink_update', 'deploy:migrate', 'deploy:precompile'
  after 'deploy:update_code', 'vecnet:write_env_vars'
  after 'deploy', 'deploy:cleanup'
  after 'deploy', 'deploy:restart'
  after 'deploy', 'vecnet:restart_workers'
end

