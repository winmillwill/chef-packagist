stack_order do
  async do
    bootstrap 'app::db'
    bootstrap 'app::search'
    bootstrap 'app::cache'
    bootstrap 'app::queue'
  end
  bootstrap 'app::app'
end

component 'app' do
  description "Packagist application"

  group 'app' do
    recipe 'packagist::app'
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
