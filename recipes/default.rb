include_recipe 'vagrant-ohai-plugin'
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
if platform_family? 'debian'
  include_recipe 'apt'
  if platform? 'ubuntu'
    apt_repository 'ondrej-php5' do
      uri           'http://ppa.launchpad.net/ondrej/php5/ubuntu'
      components    ['main']
      distribution  node.lsb.codename
      deb_src       true
      keyserver     'keyserver.ubuntu.com'
      key           '14AA40EC0831756756D7F66C4F4EA0AAE5267A6C'
    end
  end
end
