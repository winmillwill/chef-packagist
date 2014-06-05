include_recipe 'vagrant-ohai-plugin'
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
