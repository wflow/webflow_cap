namespace :mysql do
  task :setup_database_and_config do
    on roles :all do
      my_cnf = capture('cat ~/.my.cnf')
      config = {}
      %w(development production test).each do |env|

        my_cnf.match(/^user=(\w+)/)
        database_user = $1

        config[env] = {
          'adapter' => 'mysql2',
          'encoding' => 'utf8',
          'database' => "#{database_user}_#{fetch :application}_#{env}",
          'host' => 'localhost',
          'port' => 3306
        }

        config[env]['username'] = database_user

        my_cnf.match(/^password=(\w+)/)
        config[env]['password'] = $1

        execute "mysql -e 'CREATE DATABASE IF NOT EXISTS #{config[env]['database']} CHARACTER SET utf8 COLLATE utf8_general_ci;'"
      end

      execute "mkdir -p #{:shared_path}/config"
      upload! StringIO.new(config.to_yaml), "#{:shared_path}/config/database.yml"
    end
  end
  
  after   'deploy:started',       'mysql:setup_database_and_config'
end