task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require './config/environment'
end

desc "Create indexes on posts and comments"
task create_indexes: :environment do
  begin
    Mongoid.models.each &:create_indexes
    puts "Created indexes for Mongoid models."
  rescue Exception => ex
    Email.exception ex
    puts "Error creating indexes, emailed report."
  end
end

desc "Set the crontab in place for this environment"
task set_crontab: :environment do
  environment = ENV['environment']
  current_path = ENV['current_path']

  if environment.blank? or current_path.blank?
    puts "No environment or current path given, exiting."
    exit
  end

  if system("cat #{current_path}/config/cron/#{environment}.crontab | crontab")
    puts "Successfully overwrote crontab."
  else
    Email.message "Crontab overwriting failed on deploy."
    puts "Unsuccessful in overwriting crontab, emailed report."
  end
end

desc "Generate a sitemap."
task sitemap: :environment do
  require 'big_sitemap'

  include Helpers::General

  ping = ENV['debug'] ? false : true

  count = 1 # assume / works

  BigSitemap.generate(
    base_url: "https://konklone.com",
    document_root: "public/sitemap",
    url_path: "sitemap",
    ping_google: ping,
    ping_bing: ping) do

    add "/", change_frequency: "daily"

    Post.visible.desc(:published_at).each do |post|
      add post_path(post), change_frequency: "weekly"
      count += 1
    end
  end

  puts "Saved sitemap with #{count} links."
end



namespace :test do
  desc "Test sending an email"
  task send_email: :environment do
    Email.message "Hello, dear admin."
  end

  desc "Test sending an email from an exception"
  task send_error_email: :environment do
    Email.exception(Exception.new("oh no"), {test: "this"})
  end
end

# sanity test suite

task default: 'tests:all'
require 'rake/testtask'
namespace :tests do
  Rake::TestTask.new(:all) do |t|
    t.libs << "test"
    t.test_files = FileList['test/**/*_test.rb']
  end
end
