namespace :load do
  task :defaults do
    # variables with default values
    set :application_server,    fetch(:application_server, "passenger")
    set :branch,                fetch(:branch, "master")
    set :scm,                   fetch(:scm, :git)
    set :ruby_version,          fetch(:ruby_version, "2.1")

    # variables without default values
    set :deploy_via, :remote_cache
    set :keep_releases, 3
    set :use_sudo, false

    set :home,                  -> { "/docs/#{fetch :user}" }
    set :deploy_to,             -> { "/docs/#{fetch :user}/#{fetch :domain}/#{fetch :application}" }
    set :server_port,           -> { 10000 + ((fetch :user)[4..6] + "0").to_i }
    
    set :linked_files, %w{}
    
    set :default_env, -> {
      {'PATH' => "/docs/#{fetch :user}/#{fetch :domain}/#{fetch :application}/shared/bin:/opt/ruby/#{fetch :ruby_version}/bin:$PATH"}
    }
  end
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
end
