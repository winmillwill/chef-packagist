VAGRANTFILE_API_VERSION = "2"

count = 1

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  (1..count).each do |number|
    name = "box#{number}"
    config.vm.define name do |box|
      box.vm.box = 'opscode-ubuntu-12.04'
      box.vm.hostname = number == 1 ? 'drupal-packagist.org' : name
      box.vm.network "private_network", ip: "10.133.33.#{100 + number}"
      box.vm.provision 'shell', inline: 'apt-get update -q -y'
    end
  end
end
