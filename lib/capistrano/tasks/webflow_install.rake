require 'erb'
require 'pathname'

namespace :webflow do
  desc "Install webflow flavoured capistrano files"
  task :install do
    on roles :all do    
      envs = ENV['STAGES'] || 'staging,production'
    
      tasks_dir = Pathname.new('lib/capistrano/tasks')
      config_dir = Pathname.new('config')
      deploy_dir = config_dir.join('deploy')
    
      deploy_rb = File.expand_path("../../templates/deploy.rb.erb", __FILE__)
      stage_rb = File.expand_path("../../templates/stage.rb.erb", __FILE__)
      capfile = File.expand_path("../../templates/Capfile", __FILE__)

      execute "mkdir -p #{deploy_dir}"
    
      entries = [{template: deploy_rb, file: config_dir.join('deploy.rb')}]
      entries += envs.split(',').map { |stage| {template: stage_rb, file: deploy_dir.join("#{stage}.rb")} }

      ask(:htaccess_pass, nil)
    
      entries.each do |entry|
        if File.exists?(entry[:file])
          warn "[skip] #{entry[:file]} already exists"
        else
          File.open(entry[:file], 'w+') do |f|
            f.write(ERB.new(File.read(entry[:template])).result(binding))
            puts "create #{entry[:file]}"
          end
        end
      end
    
      execute "mkdir -p #{tasks_dir}"

      if File.exists?('Capfile')
        warn "[skip] Capfile already exists"
      else
        FileUtils.cp(capfile, 'Capfile')
        puts 'create Capfile'
      end    
    end
  
    puts 'Capified'
  end
end