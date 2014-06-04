#
# Cookbook Name:: test_packagist
# Recipe:: default
#
# Copyright (C) 2014 
#
# 

include_recipe 'apt' if platform_family? 'debian'
include_recipe 'application_solr'
hostsfile_entry '127.0.1.1' do
  hostname 'packagist.dev'
  action :append
end
