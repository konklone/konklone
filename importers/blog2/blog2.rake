namespace :import do
  desc "Import posts and comments from blog2"
  task :blog2 => :environment do
    
    Post.where(:import_source => "blog2").delete_all
    Comment.where(:import_source => "blog2").delete_all
    
    require 'mysql'
    
    # hardcoding useless (to other people) local credentials
    connection = Mysql.connect "localhost", "root", "", "old_blog2"
    
    Blog2.get_posts connection
    Blog2.get_comments connection
  end
end

module Blog2

  def self.get_posts(connection)
    entries = connection.query "select * from MainEntries"
    
    i = 0
    entries.each_hash do |entry|
      post = Post.new
      
      # was originally in Eastern time, depending on this being run in eastern time
      timestamp = Time.parse entry["timestamp"]
      
      post.attributes = {
        :title => dechar(entry["title"]),
        :body => dechar(entry["entry"]),
        :created_at => timestamp,
        :published_at => timestamp,
        
        :tags => [],
        :post_type => ["blog"],
        :private => true,
        :draft => true,
        
        :imported_at => Time.now,
        :import_source => "blog2", 
        :import_id => entry["id"].to_i
      }
      
      begin
        post.save!
        i += 1
      rescue BSON::InvalidStringEncoding
        puts "Invalid character somewhere in this post:\n"
        puts post.inspect
        exit
      end
      
    end
    
    puts "Imported #{i} posts from blog2. Total blog2 posts in system: #{Post.where(:import_source => "blog2").count}"
  end

  def self.get_comments(connection)
    comments = connection.query "select * from MainComments"
    
    i = 0
    comments.each_hash do |comment|
      body = dechar comment["comment"]
      if body.blank?
        puts "Blank comment body, skipping."
        next
      end
    
      post_id = comment["entryID"].to_i
      
      # was originally in Eastern time, depending on this being run in eastern time
      timestamp = Time.parse comment["timestamp"] 
      
      # potentially blank authors
      author = comment["username"].present? ? dechar(comment["username"]) : "[Anonymous]"
      
      post = Post.where(:import_source => "blog2", :import_id => post_id).first
      if post
        comment = post.comments.build(
          :author => author,
          :author_url => dechar(comment["website"]),
          :body => dechar(comment["comment"]),
          :created_at => timestamp,
          
          :imported_at => Time.now,
          :import_source => "blog2",
          :import_id => comment["id"].to_i,
          :import_post_id => post_id
        )
        
        # attr_protected fields, can't be mass-assigned
        comment.ip = comment["ip"]
        comment.hidden = !(comment["visible"] == "yes")
        comment.flagged = false
        comment.mine = false
        
        begin
          comment.save!
        rescue BSON::InvalidStringEncoding
          puts "Invalid character somewhere in this comment:\n"
          puts comment.inspect
          exit
        end
      else
        puts "Comment #{comment["id"]}, couldn't find parent ID of #{post_id}"
      end
    end
    
    puts "Imported #{i} comments from blog2. Total blog2 comments in system: #{Comment.where(:import_source => "blog2").count}"
  end

  # utf8-izes special chars
  def self.dechar(string)
    string.gsub("\222", "'").gsub("\223", "\"").gsub("\224", "\"").gsub("\227", "--").gsub("\366", "ö").gsub("\351", "é").gsub("\374", "a").gsub("\350", "é")
  end
  
end