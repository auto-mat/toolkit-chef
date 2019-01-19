source "https://supermarket.chef.io"

cookbook 'build-essential', '~> 8.2.1'
cookbook 'apache2', '~> 5.2.1'
cookbook 'java', '~> 2.2.0'
cookbook 'brightbox-ruby', '~> 1.2.2'
cookbook 'passenger_apache2', '~> 3.1.0'
cookbook 'nodejs', '~> 5.0.0'

local_cookbooks = %w(cyclescape cyclescape-backups cyclescape-user munin-plugins-rails
munin ntp postfix postgres ssl letsencrypt)
local_cookbooks.each do |local_cookbook|
  cookbook local_cookbook, path: "local-cookbooks/#{local_cookbook}"
end
