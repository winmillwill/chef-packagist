include_recipe 'packagist::install_app'

remote_file "#{Chef::Config[:file_cache_path]}/packagist_projects" do
  source 'https://drupal.org/files/releases.tsv'
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
    ./app/console packagist:bulk_add --repo-pattern 'http://git.drupal.org/project/%2\$s' --vendor drupal $(cat #{Chef::Config[:file_cache_path]}/packagist_projects | grep 7.x | awk '{ print $3 }' | sort | uniq -)
    #{update}
  }
end

cron 'symfony-update' do
  minute '*/5'
  command update
  user node.packagist.user
end
