namespace :load do
  task :defaults do
    # variables with default values
    set :application_server,    fetch(:application_server, "puma")
    set :branch,                fetch(:branch, "master")
    set :scm,                   fetch(:scm, :git)
    set :ruby_version,          fetch(:ruby_version, "2.1")

    # variables without default values
    set :deploy_via, :remote_cache
    set :keep_releases, 3
    set :use_sudo, false

    set :home,                  -> { "/docs/#{fetch :user}" }
    set :deploy_to,             -> { "/docs/#{fetch :user}/#{fetch :domain}/#{fetch :application}" }
    set :server_port,           -> { 10000 + ((fetch :user)[3..6] + "0").to_i }
    
    set :default_env, {
      'PATH' => "PATH=/docs/#{fetch :user}/.gem/ruby/#{fetch :ruby_version}/bin:/opt/ruby/#{fetch :ruby_version}/bin:$PATH"
    }
  end
end

namespace :runit do
  task :setup_application_server do
    on roles :all do
      daemon_script = <<-EOF
#!/bin/bash -e
export HOME=#{fetch :home}
source $HOME/.bashrc
cd #{fetch :deploy_to}/current
exec bundle exec #{fetch :application_server} start -p #{fetch :server_port} -e production -d 2>&1
    EOF
    
      log_script = <<-EOF
#!/bin/bash -e
exec svlogd -tt ./main
    EOF
    
      execute                 "mkdir -p #{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"
      execute                 "mkdir -p #{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}/log/main"
      upload! StringIO.new(daemon_script),  "#{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}/run"
      upload! StringIO.new(log_script),     "#{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}/log/run"
      execute                 "chmod +x #{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}/run"
      execute                 "chmod +x #{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}/log/run"
      execute                 "ln -nfs #{fetch :home}/etc/sv/run-rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application} ~/etc/service/rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"
    end
  end
  
  after   'deploy:started', 'runit:setup_application_server'
end

namespace :htaccess do
  task :create do
    on roles :all do
      if test("[ -e #{shared_path}/.htaccess ]")
        warn "[skip] .htaccess already exists"
      elsif fetch(:password_protected)
        ask(:htaccess_user, fetch(:user))
        ask(:htaccess_pass, nil)
        
        htaccess_content = <<-EOF
AuthName "#{fetch :application}"
AuthType Basic
AuthUserFile #{shared_path}/.htpasswd
Require valid-user
        EOF
        upload! StringIO.new(htaccess_content), "#{shared_path}/.htaccess"
        execute "htpasswd -dbc #{shared_path}/.htpasswd #{fetch :htaccess_user} #{fetch :htaccess_pass}"
      end
    end
  end
  
  task :remove do
    on roles :all do
      if ("[ -e #{shared_path}/.htaccess ]")
        execute "rm -f #{shared_path}/.htaccess"
        execute "rm -f #{shared_path}/.htpasswd"
        execute "rm -f #{current_path}/.htaccess"
      end
    end
  end
    
  after 'deploy:updated', 'htaccess:create'
end

namespace :apache do
  task :setup_reverse_proxy do
    on roles :all do
      htaccess = <<-EOF
RewriteEngine On
RewriteRule ^(.*)$ http://localhost:#{fetch :server_port}/$1 [P]
    EOF
      path =              "#{fetch :home}/#{fetch :domain}"
      execute                 "mkdir -p #{path}"
      upload! StringIO.new(htaccess),       "#{path}/.htaccess"
      execute                 "chmod +r #{path}/.htaccess"
    end
  end
  
  after   'deploy:started', 'apache:setup_reverse_proxy'
end

namespace :deploy do
  task :start do
    on roles :all do
      execute "sv start #{fetch :home}/etc/service/rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"
    end
  end
  task :stop do
    on roles :all do
      execute "sv stop #{fetch :home}/service/rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"
    end
  end
  task :restart do
    on roles :all do
      execute "sv restart #{fetch :home}/service/rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"
    end
  end

  task :symlink_shared do
    on roles :all do
      execute "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
      
      if fetch(:password_protected)
        execute "ln -nfs #{shared_path}/.htaccess #{release_path}/.htaccess"
      end
    end
  end

  before  :updated, :symlink_shared
end
