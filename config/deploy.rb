set :environment, 'production'

set :user, 'klondike'
set :application, 'konklone'

set :gems_dir, "/home/#{user}/webapps/#{application}/gems"
set :deploy_to, "/home/#{user}/webapps/#{application}/#{application}/"

set :domain, 'konklone.com'

set :scm, :git
set :repository, "git@github.com:konklone/industries.git"
set :branch, 'master'

set :deploy_via, :remote_cache
set :runner, user
set :admin_runner, runner

role :app, domain
role :web, domain

set :use_sudo, false
after "deploy", "deploy:cleanup"
after "deploy:update_code", "deploy:shared_links"
after "deploy:update_code", "deploy:bundle_install"
# after "deploy:update_code", "deploy:create_indexes"

namespace :deploy do
  task :start do; end
  task :stop do; end
  task :migrate do; end
  
  desc "Restart the server"
  task :restart, :roles => :app, :except => {:no_release => true} do
    run "touch #{File.join current_path, 'tmp', 'restart.txt'}"
  end
  
#   desc "Create indexes"
#   task :create_indexes, :roles => :app, :except => {:no_release => true} do
#     run "cd #{release_path} && rake create_indexes"
#   end
  
  desc "Install Ruby gems"
  task :bundle_install, :roles => :app, :except => {:no_release => true} do
    run "cd #{release_path} && bundle install --local --path=#{gems_dir}"
  end
  
  desc "Get shared files into position"
  task :shared_links, :roles => [:web, :app] do
    run "ln -nfs #{shared_path}/config.yml #{release_path}/config/config.yml"
    run "ln -nfs #{shared_path}/config.ru #{release_path}/config.ru"
    run "rm #{File.join release_path, 'public', 'system'}"
    run "rm #{File.join release_path, 'log'}"
  end
end