# Imports all blog posts and comments from my LiveJournal
namespace :import do
  desc "Import posts and comments from blog0"
  task :blog0 => :environment do
    current_dir = Dir.pwd
    Dir.chdir "importers/blog0"
    
    Blog0.get_posts
    Blog0.get_comments
    
    Dir.chdir current_dir
  end
end

module Blog0

  def self.get_posts
    post_count = 0

    

    puts "Posts loaded: #{post_count}\n\n"
  end


  def self.get_comments
    comment_count = 0
    
    puts "Comments loaded: #{comment_count}\n\n"
  end
  
end