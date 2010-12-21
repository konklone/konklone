task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require 'config/environment'
end

load 'other/fixtures.rake'
load 'other/importers/blog1.rake'

desc "Create indexes on posts and comments"
task :create_indexes => :environment do
  Post.create_indexes
  Comment.create_indexes
  puts "Created indexes for posts and comments."
end