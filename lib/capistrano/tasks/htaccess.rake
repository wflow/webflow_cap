namespace :htaccess do  
  task :password_protection do
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