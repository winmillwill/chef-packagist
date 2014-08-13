include_recipe 'packagist::install_app'

console_path = File.join(
  node.packagist.web_root, 'packagist', 'app', 'console'
)

include_recipe 'supervisor'
supervisor_service "packagist_add" do
  command     "#{console_path} rabbitmq:consume add_packages"
  user        node.packagist.user
  environment({
    "HOME" => "/home/#{node.packagist.user}"
  })
  autorestart false
end
