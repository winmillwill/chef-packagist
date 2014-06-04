name 'db_master'
description 'master of all dbs'
run_list 'recipe[apt]', 'recipe[database::mysql]', 'recipe[database::master]'
default_attributes 'mysql' => {
  'server_root_password' => 'pass',
  'server_repl_password' => 'pass',
  'server_debian_password' => 'pass'
}
