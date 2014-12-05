require 'erb'
require 'pathname'
require 'capistrano/configuration/question.rb'

namespace :webflow do
  desc "Install webflow flavoured capistrano files"
  task :install do
    question = Capistrano::Configuration::Question

    repository_url = if File.exists?(Dir.getwd + '/.git')
      `git config --get remote.origin.url`.strip
    end

    set :application, ask("Application name", File.basename(Dir.getwd))
    set :ruby_version, ask("Ruby version", "2.1.5")
    set :repo_url, ask("Repository URL", repository_url)
    set :user, ask("Username", "f909999")
    set :domain, ask("Domain", "example.com")
    set :server, -> { ask("Server", fetch(:domain)) }
    set :server_port, -> { 10000 + ((fetch :user)[4..6] + "0").to_i }

    @application = fetch(:application)
    @ruby_version = fetch(:ruby_version)
    @repo_url = fetch(:repo_url)
    @user = fetch(:user)
    @domain = fetch(:domain)
    @server = fetch(:server)
    @server_port = fetch(:server_port)
          
    envs = ENV['STAGES'] || 'staging,production'
  
    tasks_dir = Pathname.new('lib/capistrano/tasks')
    config_dir = Pathname.new('config')
    deploy_dir = config_dir.join('deploy')
  
    deploy_rb = File.expand_path("../../templates/deploy.rb.erb", __FILE__)
    stage_rb = File.expand_path("../../templates/stage.rb.erb", __FILE__)
    capfile = File.expand_path("../../templates/Capfile", __FILE__)

    FileUtils.mkdir_p deploy_dir
  
    entries = [{template: deploy_rb, file: config_dir.join('deploy.rb')}]
    entries += envs.split(',').map { |stage| {template: stage_rb, file: deploy_dir.join("#{stage}.rb")} }
  
    entries.each do |entry|
      if File.exists?(entry[:file]) && question.new("Overwrite #{entry[:file]}?", 'y').call != 'y'
        warn "[skip] #{entry[:file]} already exists"
      else
        File.open(entry[:file], 'w+') do |f|
          f.write(ERB.new(File.read(entry[:template])).result(binding))
          puts "create #{entry[:file]}"
        end
      end
    end
  
    FileUtils.mkdir_p tasks_dir

    if File.exists?('Capfile') && question.new("Overwrite Capfile?", 'y').call != 'y'
      warn "[skip] Capfile already exists"
    else
      FileUtils.cp(capfile, 'Capfile')
      puts 'create Capfile'
    end    
  
    puts 'Capified'
  end
end