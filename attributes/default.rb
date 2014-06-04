default.packagist.user = 'root'
default.packagist.repository = 'https://github.com/composer/packagist'
default.packagist.ref = 'master'
default.packagist.web_root = '/var/www'
default.packagist.parameters['github.client_id'] = 'notarealclientid'
default.packagist.parameters['github.client_secret'] = 'notarealsecretid'
default.packagist.parameters.packagist_host = 'localhost'
default.packagist.nelmio_solarium = {
  'clients' => {
    'default' => {
      'dsn' => 'http://localhost:8080/solr'
    }
  }
}
