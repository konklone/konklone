task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require './config/environment'
end

# load 'importers/blog0/blog0.rake'
# load 'importers/blog1/blog1.rake'
# load 'importers/blog2/blog2.rake'
# load 'importers/blog3/blog3.rake'

# Dir.glob("syncers/*.rake").each {|f| load f}

desc "Create indexes on posts and comments"
task :create_indexes => :define_import_indexes do
  begin
    Mongoid.models.each &:create_indexes
    puts "Created indexes for posts and comments."
  rescue Exception => ex
    Email.exception ex
    puts "Error creating indexes, emailed report."
  end
end

# indexes on fields used only in importing
task :define_import_indexes => :environment do
  class Post
    index imported_at: 1
    index import_source: 1
    index import_source_filename: 1
    index import_song_filename: 1
    index import_id: 1
    index import_sequence: 1 # LJ post sequence IDs
  end

  class Comment
    index imported_at: 1
    index import_source: 1
    index import_source_filename: 1
    index import_id: 1
    index import_post_id: 1
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
task :sitemap => :environment do
  require 'big_sitemap'

  include Helpers::General

  ping = ENV['debug'] ? false : true

  count = 1 # assume / works

  BigSitemap.generate(
    base_url: "http://konklone.com",
    document_root: "public/sitemap",
    url_path: "sitemap",
    ping_google: ping,
    ping_bing: ping) do

    add "/", change_frequency: "daily"

    Post.visible.channel("blog").desc(:published_at).each do |post|
      add post_path(post), change_frequency: "weekly"
      count += 1
    end
  end

  puts "Saved sitemap with #{count} links."
end


namespace :cache do
  desc "Reset post cache"
  task reset: :environment do
    if config[:site]['cache_enabled']
      # Post.visible.each &:uncache!
      system "rm #{Environment.cache_dir}/*"
    end
  end
end