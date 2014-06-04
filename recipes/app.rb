include_recipe 'packagist::default'

%w{
  subversion
  mercurial
  curl
}.each do |pkg|
  package pkg do
    action [:install, :upgrade]
  end
end

include_recipe 'php::module_mysql'
if platform_family? 'debian'
  package 'php5-json'
  package 'php5-curl'
  web = 'www-data'
else
  web = 'nginx'
  package 'php-xml'
end
node.set['php-fpm']['user'] = web
node.set['php-fpm']['group'] = web

include_recipe 'build-essential'
include_recipe 'composer'
include_recipe 'php-fpm'
include_recipe 'nginx'
include_recipe 'hostname'

# certificate_manage node.fqdn do
#   owner web
#   group web
#   nginx_cert true
# end

template "/etc/nginx/sites-available/packagist" do
  mode 0644
  source "packagist.conf.erb"
  # variables ({
  #   ssl_key: "/etc/ssl/#{node.fqdn}.key",
  #   ssl_sert: "/etc/ssl/#{node.fqdn}.cert"
  # })
end

bash "nginx disable default" do
  only_if { File.exists?("/etc/nginx/sites-enabled/default") }
  code "nxdissite default"
end

bash "nginx enable packagist" do
  not_if { File.exists?("/etc/nginx/sites-enabled/packagist") }
  code "nxensite packagist"
end

# php redis
include_recipe 'git'
git "/tmp/phpredis" do
  repository "https://github.com/nicolasff/phpredis"
  action :checkout
end

if platform_family? 'debian'
  php_confd = '/etc/php5/conf.d'
else
  php_confd = '/etc/php.d'
end

bash 'install phpredis' do
  not_if 'php -m | grep redis'
  code <<-EOC
    cd /tmp/phpredis
    phpize
    ./configure
    make
    make install
    echo "extension=redis.so" > #{php_confd}/redis.ini
  EOC
end

directory node.packagist.web_root do
  recursive true
end

# web user must be able to create ~/.composer
directory '/var/www' do
  owner node['php-fpm']['user']
end

packagist_path = File.join(node.packagist.web_root, 'packagist')
directory packagist_path do
  owner node.packagist.user
  group node['php-fpm']['group']
end

git packagist_path do
  user node.packagist.user
  group node['php-fpm']['group']
  repository node.packagist.repository
  reference node.packagist.ref
  action :checkout
end

ruby_block 'packagist yaml' do
  block do
    require 'yaml'
    def server_ip(pattern)
      host = Discovery.search(
        pattern,
        node: node,
        empty_ok: true,
        remove_self: false,
        raw_search: true,
        local_fallback: true
      ) || node
      discovery_ipaddress(remote_node: host)
    end
    node.set['packagist']['parameters']['database_host'] = server_ip('roles:db_master')
    node.set['packagist']['parameters']['redis_dsn'] = "redis://#{server_ip('recipes:packagist\:\:redis')}/1"
    node.set['packagist']['nelmio_solarium']['clients']['default']['dsn'] = "http://#{server_ip('recipes:packagist\:\:solr')}:8080/solr/packagist"
    node.set['packagist']['old_sound_rabbit_mq']['connections']['default']['host'] = server_ip('recipes:rabbitmq\:\:default')
    params = YAML.load_file(File.join(packagist_path, 'app/config/parameters.yml.dist'))
    node.packagist.parameters.each do |param, value|
      params['parameters'][param] = value.is_a?(String) ? value : value.to_h
    end
    params['nelmio_solarium'] = node.packagist.nelmio_solarium.to_hash
    params['old_sound_rabbit_mq'] = node.packagist.old_sound_rabbit_mq.to_hash
    File.open(File.join(packagist_path, 'app/config/parameters.yml'), 'w') do |f|
      f.write params.to_yaml
    end
  end
end

composer_project packagist_path do
  user node.packagist.user
  group node['php-fpm']['group']
  umask 0002
end

# cron doesn't like \n
update = "cd #{packagist_path} && \
  app/console packagist:update --no-debug --env=prod && \
  app/console packagist:dump --no-debug --env=prod && \
  app/console packagist:index --no-debug --env=prod --all"

cron 'symfony-update' do
  minute '*/5'
  command update
  user node.packagist.user
end

bash "symfony install" do
  user node.packagist.user
  group node['php-fpm']['group']
  umask 0002
  cwd packagist_path
  returns [0, 1]
  code %Q{
    ./app/console -q -n --no-ansi assets:install --symlink web
    ./app/console -q -n --no-ansi doctrine:database:create
    ./app/console -q -n --no-ansi doctrine:schema:create
    ./app/console -q -n --no-ansi cache:clear --env prod
    #{update}
  }
end

bash "add packages" do
  user node.packagist.user
  group node['php-fpm']['group']
  umask 0002
  cwd packagist_path
  returns [0, 1]
  action :nothing
  code %Q{
    ./app/console -q -n --no-ansi packagist:add --vendor drupal --repo-pattern 'http://git.drupal.org/project/%2$s.git' `cat #{Chef::Config[:file_cache_path]}/projects` &>./app/logs/prod
  }
end

remote_file "#{Chef::Config[:file_cache_path]}/projects" do
  source "https://gist.githubusercontent.com/winmillwill/93580a4f52852975bc65/raw/641feecb7948b819c81414cc621f065af3df8853/gistfile1.txt"
  action :create_if_missing
  notifies :run, "bash[add packages]"
end
