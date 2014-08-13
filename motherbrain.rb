stack_order do
  async do
    bootstrap 'app::db'
    bootstrap 'app::search'
    bootstrap 'app::cache'
    bootstrap 'app::queue'
  end
  bootstrap 'app::app_worker'
  bootstrap 'app::app_master'
end

component 'app' do
  description "Packagist application"

  group 'app_master' do
    recipe 'packagist::bootstrap_app'
  end
  group 'app_worker' do
    recipe 'packagist::app_worker'
  end
  group 'cache' do
    recipe 'packagist::redis'
  end
  group 'search' do
    recipe 'packagist::solr'
  end
  group 'db' do
    role 'db_master'
  end
  group 'queue' do
    recipe 'packagist::rabbitmq'
  end
end
