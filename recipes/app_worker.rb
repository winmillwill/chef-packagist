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
  process_name '%(program_name)s_%(process_num)02d'
  numprocs 2
  autorestart false
end
