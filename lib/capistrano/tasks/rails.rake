namespace :load do
  task :defaults do
    set :runit_service_dir, -> {"#{fetch :home}/etc/service/rails-#{fetch :server_port}-#{fetch :domain}-#{fetch :application}"}
  end
end

namespace :rails do
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
      invoke                  'htaccess:setup_reverse_proxy'
    end
  end
  
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
  
  after   'deploy:published', 'rails:setup_application_server'
end