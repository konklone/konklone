task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require 'config/environment'
end

load 'other/fixtures.rake'
Dir.glob("importers/*.rake").each do |file|
  load file
end

desc "Create indexes on posts and comments"
task :create_indexes => :define_import_indexes do
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
  end
  
  class Comment
    index :imported_at
    index :import_source
    index :import_source_filename
    index :import_id
    index :import_post_id
  end
end