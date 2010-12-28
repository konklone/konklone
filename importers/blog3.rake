require 'redcloth'

namespace :import do
  desc "Import posts and comments from blog3"
  task :blog3 => :environment do
    
    Post.delete_all :conditions => {:import_source => "blog3"}
    Comment.delete_all :conditions => {:import_source => "blog3"}
    
    require 'importers/blog3/environment'
    
    get_posts
    get_comments
  end
end

def get_posts
  OldPost.all.each do |old_post|
    post = Post.new
    if old_post.title.present?
      post.attributes = {
        :title => dechar(old_post.title),
        :display_title => old_post.show_title
      }
    else
      post.attributes = {
        :title => "untitled",
        :display_title => false
      }
    end
      
    post.attributes = {
      :body => process_body(old_post.body),
      :created_at => old_post.created_at,
      :updated_at => old_post.updated_at,
      :published_at => old_post.created_at,
      
      :tags => old_post.categories.all.map {|c| c.name.downcase},
      :post_type => ["blog"],
      :private => false,
      :draft => !old_post.visible,
      
      :imported_at => Time.now,
      :import_source => "blog3", 
      :import_song_filename => old_post.filename,
      :import_id => old_post.id
    }
    
    begin
      post.save!
    rescue BSON::InvalidStringEncoding
      puts "Invalid character somewhere in this post:\n"
      puts post.inspect
      exit
    end
  end
  
  puts "Loaded #{Post.where(:import_source => "blog3").count} posts from blog3."
end

def get_comments
  OldComment.all.each do |old_comment|
    post = Post.where(:import_source => "blog3", :import_id => old_comment.post_id).first
    if post
      comment = post.comments.build(
        :author => dechar(old_comment.name),
        :author_url => dechar(old_comment.website),
        :body => dechar(old_comment.body),
        :created_at => old_comment.created_at,
        :updated_at => old_comment.updated_at,
        :hidden => !old_comment.visible,
        :flagged => false,
        :mine => old_comment.mine,
        
        :imported_at => Time.now,
        :import_source => "blog3",
        :import_id => old_comment.id,
        :import_post_id => old_comment.post_id
      )
      comment.ip = old_comment.ip
      
      begin
        comment.save!
      rescue BSON::InvalidStringEncoding
        puts "Invalid character somewhere in this comment:\n"
        puts comment.inspect
        exit
      end
    
    else
      puts "Comment #{old_comment.id}'s parent post #{old_comment.post_id} not found!"
      exit
    end
  end
  
  puts "Loaded #{Comment.where(:import_source => "blog3").count} comments from blog3."
end

# utf8-izes special chars
def dechar(string)
  string.gsub("\222", "'").gsub("\223", "\"").gsub("\224", "\"").gsub("\227", "--").gsub("\366", "ö")
end

# take care of some minimal un-textiling
def process_body(body)
  body = dechar body
  body = body.gsub /^p=\. ([^\n]+?)$/, "<p style=\"text-align: center\">\\1</p>"
  body = body.gsub /^bq\. ([^\n]+?)$/, "<blockquote>\\1</blockquote>"
  body = body.gsub(/!([^\s]+)!:?([^\s]*)/) do
    img = "<img src=\"#{$1}\"/>"
    img = "<a href=\"#{$2}\">#{img}</a>" if $2.present?
    img
  end
  body = body.gsub(/\"([^\"]+)\":([^\s]+)/) {"<a href=\"#{$2}\">#{$1}</a>"}
  body = body.gsub /\[cut\](\s*)/, "\n\n"
  
  body
end