#
# Cookbook Name:: test_packagist
# Recipe:: default
#
# Copyright (C) 2014 
#
# 

include_recipe 'solr_app'
solr_app 'packagist' do
  cookbook cookbook_name.to_s
end

remote_file File.join(node.solr_app.solr_home, 'packagist', 'conf', 'schema.xml') do
  source 'https://raw.githubusercontent.com/composer/packagist/master/doc/schema.xml'
  notifies :restart, 'service[tomcat]'
  owner 'tomcat6'
  group 'tomcat6'
end

hostsfile_entry '127.0.1.1' do
  hostname 'packagist.dev'
  action :append
end
