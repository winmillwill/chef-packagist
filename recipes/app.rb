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
  only_if { File.exists?("/etc/nginx/sites-enabled/000-default") }
  code "nxdissite 000-default"
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
  if platform? 'ubuntu'
    php_confd = '/etc/php5/mods-available'
  end
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
