namespace :htaccess do  
  task :password_protection do
    on roles :all do
      path = "#{fetch :home}/#{fetch :domain}/htdocs"
      
      if test("[ -e #{shared_path}/.htpasswd ]")
        info "[skip] password protection is already active"
      elsif fetch(:password_protected)
        ask(:htaccess_user, fetch(:user))
        ask(:htaccess_pass, nil)
        
        execute "echo 'AuthName #{fetch :application}' >> #{path}/.htaccess"
        execute "echo 'AuthType Basic' >> #{path}/.htaccess"
        execute "echo 'AuthUserFile #{shared_path}/.htpasswd' >> #{path}/.htaccess"
        execute "echo 'Require valid-user' >> #{path}/.htaccess"

        execute "htpasswd -dbc #{shared_path}/.htpasswd #{fetch :htaccess_user} #{fetch :htaccess_pass}"
      end
    end
  end
  
  task :change_credentials do
    on roles :all do
      ask(:htaccess_user, fetch(:user))
      ask(:htaccess_pass, nil)
      
      execute "htpasswd -dbc #{shared_path}/.htpasswd #{fetch :htaccess_user} #{fetch :htaccess_pass}"
    end
  end
  
  after   'deploy:finished', :password_protection
end