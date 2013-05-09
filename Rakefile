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
  # todo: change this to Mongoid.models.each
  Post.create_indexes
  Comment.create_indexes
  puts "Created indexes for posts and comments."
end

# indexes on fields used only in importing
task :define_import_indexes => :environment do
  class Post
    index :imported_at
    index :import_source
    index :import_source_filename
    index :import_song_filename
    index :import_id
    index :import_sequence # LJ post sequence IDs
  end
  
  class Comment
    index :imported_at
    index :import_source
    index :import_source_filename
    index :import_id
    index :import_post_id
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