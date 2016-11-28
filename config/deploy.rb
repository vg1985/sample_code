# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'voipessential'
set :repo_url, 'git@bitbucket.org:Sipsurge/sipsurge-new.git'
set :stages, %w(production staging)
set :default_stage, "staging"
set :branch, "finance"

set :deploy_to, '/home/railsmancer/voipessential'
set :use_sudo, false

set :rvm_type, :user
set :rvm_ruby_version, '2.1.2'

set :keep_releases, 2

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
    end
  end

  task :compile_assets do
    #run "cd #{release_path}; RAILS_ENV=staging rake assets:precompile"
  end

  task :invoke do
    on roles(:app) do
      execute("ln -s #{shared_path}/database.yml #{release_path}/config/database.yml")
    end
  end

  def run_remote_rake(rake_cmd)
    rake_args = ENV['RAKE_ARGS'].to_s.split(',')
    cmd = "cd #{fetch(:latest_release)} && #{fetch(:rake, "rake")} RAILS_ENV=#{rails_env} #{rake_cmd}"
    cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
    run cmd
    set :rakefile, nil if exists?(:rakefile)
  end

  before "deploy:compile_assets", :invoke
  after :publishing, :restart
end
