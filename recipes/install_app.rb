include_recipe 'packagist::app'
# web user must be able to create ~/.composer
directory '/var/www' do
  owner node['php-fpm']['user']
end
chef_gem 'deep_merge'
require 'deep_merge'

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
  action :sync
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
        local_fallback: true,
        environment_aware: true
      ) || node
      discovery_ipaddress(remote_node: host)
    end
    node.set['packagist']['parameters']['database_host'] = server_ip('roles:db_master')
    node.set['packagist']['parameters']['redis_dsn'] = "redis://#{server_ip('recipes:packagist\:\:redis')}/1"
    node.set['packagist']['nelmio_solarium']['clients']['default']['dsn'] = "http://#{server_ip('recipes:packagist\:\:solr')}:8080/solr/packagist"
    node.set['packagist']['old_sound_rabbit_mq']['connections']['default']['host'] = server_ip('recipes:rabbitmq\:\:default')
    params = YAML.load_file(File.join(packagist_path, 'app/config/parameters.yml.dist'))
    %w(parameters nelmio_solarium old_sound_rabbit_mq).each do |key|
      params[key] ||= {}
      params[key].deep_merge! node.packagist.send(key).to_hash
    end
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
