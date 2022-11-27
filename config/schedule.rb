# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

env :PATH, ENV['PATH']
env "GEM_HOME", ENV["GEM_HOME"]
set :output, "#{path}/log/cron.log"
set :chronic_options, :hours24 => true

every 1.day, :at => '06:00' do #
  runner "ImportProductJob.perform_later"
end

every 1.day, :at => '23:40' do #
  rake "file:clear_temp_excel_price_folder"
end

every 1.day, :at => '23:45' do #
  rake "file:create_production_log_zip_every_day"
end

