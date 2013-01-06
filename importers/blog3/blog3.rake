# encoding: utf-8

namespace :import do
  desc "Import posts and comments from blog3"
  task :blog3 => :environment do
    
    Post.where(:import_source => "blog3").delete_all
    Comment.where(:import_source => "blog3").delete_all
    
    require 'importers/blog3/environment'
    
    Blog3.get_posts
    Blog3.get_comments
  end
end

module Blog3

  def self.get_posts
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

  def self.get_comments
    OldComment.all.each do |old_comment|
      post = Post.where(:import_source => "blog3", :import_id => old_comment.post_id).first
      if post
        comment = post.comments.build(
          :author => dechar(old_comment.name),
          :author_url => dechar(old_comment.website),
          :body => dechar(old_comment.body),
          :created_at => old_comment.created_at,
          
          :imported_at => Time.now,
          :import_source => "blog3",
          :import_id => old_comment.id,
          :import_post_id => old_comment.post_id
        )
        
        # attr_protected fields, can't be mass-assigned
        comment.ip = old_comment.ip
        comment.hidden = !old_comment.visible
        comment.flagged = false
        comment.mine = old_comment.mine
        
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
  def self.dechar(string)
    string.gsub("\222", "'").gsub("\223", "\"").gsub("\224", "\"").gsub("\227", "--").gsub("\366", "ö")
  end

  # take care of some minimal un-textiling
  def self.process_body(body)
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
  
end