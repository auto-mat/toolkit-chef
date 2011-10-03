#
# Cookbook Name:: toolkit
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

include_recipe 'passenger'
include_recipe 'postgres'
include_recipe 'ruby19'

# We can install bundler with the ubuntu version of gem ...
gem_package "bundler" do
  gem_binary "/usr/bin/gem1.9.1"
  action :install
end

# ... but it installs binaries into a non-PATH directory
# See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=448639
link "/usr/bin/bundle" do
  to "/var/lib/gems/1.9.1/bin/bundle"
end

# Install a very old version of nodejs
package "nodejs"

user "cyclekit" do
  action :create
end

# Create the database user. For now, it's a superuser.
script "create cyclekit db user" do
  interpreter "bash"
  user "postgres"
  group "postgres"
  cwd "/var/lib/postgresql"
  code <<-EOH
    createuser cyclekit -s
  EOH
  not_if %q{test -n "`sudo -u postgres psql template1 -A -t -c '\du cyclekit'`"} # Mmm, hacky
end

deploy_dir = "/var/www/toolkit"

[deploy_dir, deploy_dir + "/shared/config"].each do |dir|
  directory deploy_dir + "/shared/config" do
    owner "cyclekit"
    group "cyclekit"
    recursive true
  end
end

template deploy_dir + "/shared/config/database.yml" do
  source "database.example.yml"
  owner "cyclekit"
  group "cyclekit"
  mode "0644"
end

deploy_revision deploy_dir do
  repo "https://github.com/cyclestreets/toolkit.git"
  revision "master"
  user "cyclekit"
  group "cyclekit"
  before_migrate do
    current_release_directory = release_path
    running_deploy_user = new_resource.user
    bundler_depot = new_resource.shared_path + '/bundle'
    excluded_groups = %w(development test)

    script 'Bundling the gems' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      code <<-EOS
        bundle install --quiet --deployment --path #{bundler_depot} \
        --without #{excluded_groups.join(' ')}
      EOS
    end
  end
  migrate true
  migration_command "bundle exec rake db:migrate"
  environment "RAILS_ENV" => "production"
  action :deploy
  restart_command "touch tmp/restart.txt"
end
