%w{
  subversion
  mercurial
  php5-json
  php5-mysql
  curl
}.each do |pkg|
  package pkg do
    action [:install, :upgrade]
  end
end

include_recipe 'composer'
include_recipe 'php-fpm'
include_recipe 'nginx'

template "/etc/nginx/sites-available/packagist" do
  mode 0644
  source "packagist.conf.erb"
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

bash "install phpredis" do
  not_if "php -m | grep redis"
  code <<-EOC
    cd /tmp/phpredis
    phpize
    ./configure
    make
    make install
    echo "extension=redis.so" > /etc/php5/conf.d/redis.ini
  EOC
end

directory node.packagist.web_root do
  recursive true
end

# web user must be able to create ~/.composer
directory '/var/www' do
  owner 'www-data'
end

packagist_path = File.join(node.packagist.web_root, 'packagist')
directory packagist_path do
  owner node.packagist.user
  group 'www-data'
end

git packagist_path do
  user node.packagist.user
  group 'www-data'
  repository node.packagist.repository
  reference node.packagist.ref
  action :checkout
end

ruby_block 'packagist yaml' do
  block do
    require 'yaml'
    params = YAML.load_file(File.join(packagist_path, "app/config/parameters.yml.dist"))
    params['parameters']['github.client_id'] = node.packagist.github.client_id
    params['parameters']['github.client_secret'] = node.packagist.github.client_secret
    params['parameters']['packagist_host'] = node.packagist.packagist_host
    params['parameters']['database_password'] = node.mysql.server_root_password
    params['nelmio_solarium'] = node.packagist.nelmio_solarium.to_hash
    File.open(File.join(packagist_path, 'app/config/parameters.yml'), 'w') do |f|
      f.write params.to_yaml
    end
  end
end

composer_project packagist_path do
  user node.packagist.user
  group 'www-data'
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
  group 'www-data'
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
