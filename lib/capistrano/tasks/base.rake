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
      'PATH' => "/docs/#{fetch :user}/.gem/ruby/#{fetch :ruby_version}/bin:/opt/ruby/#{fetch :ruby_version}/bin:$PATH"
    }

    set :runit_service_dir, -> {"#{fetch :home}/etc/service/rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"}
  end
end

namespace :runit do
  task :setup_application_server do
    on roles :all do
      daemon_name = "rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"
      runit_dir = "#{fetch :home}/etc/sv/#{daemon_name}"

      if test("[ -e #{runit_dir} ]")
        info("runit ready @ #{runit_dir}")
        next
      end

      daemon_script = <<-EOF
#!/bin/bash -e
exec 2>&1
export HOME=#{fetch :home}
export PATH=#{fetch(:default_env)['PATH']}
source $HOME/.bashrc
cd #{fetch :deploy_to}/current
exec bundle exec #{fetch :application_server} -p #{fetch :server_port} -e production 2>&1
    EOF
    
      log_script = <<-EOF
#!/bin/bash -e
exec svlogd -tt ./main
    EOF
    
      execute                 "mkdir -p #{runit_dir}"
      execute                 "mkdir -p #{runit_dir}/log/main"
      upload! StringIO.new(daemon_script),  "#{runit_dir}/run"
      upload! StringIO.new(log_script),     "#{runit_dir}/log/run"
      execute                 "chmod +x #{runit_dir}/run"
      execute                 "chmod +x #{runit_dir}/log/run"
      execute                 "ln -nfs #{runit_dir} #{fetch :runit_service_dir}"
    end
  end
  
  after   'deploy:started', 'runit:setup_application_server'
end

namespace :htaccess do
  task :create do
    on roles :all do
      if test("[ -e #{shared_path}/.htaccess ]")
        info "[skip] .htaccess already exists"
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
      if test("[ -e #{shared_path}/.htaccess ]")
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
      path = "#{fetch :home}/#{fetch :domain}/htdocs"

      if test("[ -e #{path} ]")
        info "reverse proxy configured @ #{path}/.htaccess"
        next
      end

      htaccess = <<-EOF
RewriteEngine On
RewriteRule ^(.*)$ http://localhost:#{fetch :server_port}/$1 [P]
    EOF
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
      execute "sv start #{fetch :runit_service_dir}"
    end
  end
  task :stop do
    on roles :all do
      execute "sv stop #{fetch :runit_service_dir}"
    end
  end
  task :restart do
    on roles :all do
      execute "sv restart #{fetch :runit_service_dir}"
    end
  end

  task :status do
    on roles :all do
      execute "sv status #{fetch :runit_service_dir}"
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
