include_recipe 'packagist::install_app'

remote_file "#{Chef::Config[:file_cache_path]}/packagist_projects" do
  source 'https://gist.githubusercontent.com/winmillwill/93580a4f52852975bc65/raw/641feecb7948b819c81414cc621f065af3df8853/gistfile1.txt'
  action :create_if_missing
end

packagist_path = File.join(node.packagist.web_root, 'packagist')

# cron doesn't like \n
update = "cd #{packagist_path} && \
  app/console packagist:dump --no-debug --env=prod && \
  app/console packagist:index --no-debug --env=prod --all"

bash 'symfony install' do
  user node.packagist.user
  group node['php-fpm']['group']
  umask 0002
  cwd packagist_path
  returns [0, 1]
  code %Q{
    ./app/console -q -n --no-ansi assets:install --symlink web
    ./app/console -q -n --no-ansi doctrine:schema:create
    ./app/console -q -n --no-ansi cache:clear --env prod
    ./app/console packagist:bulk_add --repo-pattern 'http://git.drupal.org/project/%2\$s' --vendor drupal #{Chef::Config[:file_cache_path]}/packagist_projects
    #{update}
  }
end

cron 'symfony-update' do
  minute '*/5'
  command update
  user node.packagist.user
end
