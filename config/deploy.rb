# config valid for current version and patch releases of Capistrano
lock "~> 3.17.0"

set :branch, 'main'
set :application, "adventer"
set :repo_url, "git@github.com:stap780/#{fetch(:application)}.git"
set :deploy_to, "/var/www/#{fetch(:application)}"
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/pdf', 'vendor/bundle', 'public', 'storage', 'lib/tasks')
set :format, :pretty
set :log_level, :info
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# set :delayed_job_default_hooks, false
after 'deploy:publishing', 'unicorn:restart'

if Rake::Task.task_defined?('deploy:published')
  after 'deploy:published', 'delayed_job:default'
end
