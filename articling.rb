#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

configure do
  MongoMapper.database = 'articling'
end


get '/' do
  Article.all(:order => "created_at ASC").map do |article|
    "#{article.title}:\n<br/>#{article.body}"
  end.join "\n\n<br/><br/>"
end

get "/articles.json" do
  Article.all.to_json
end


class Article
  include MongoMapper::Document
  
  key :slug, String, :required => true, :index => true
  key :title, String
  key :body, String
  
  ensure_index :type
  ensure_index :tags
  ensure_index :source
  ensure_index :private
  ensure_index :imported_at
  
  timestamps!
  
  def self.slug_for(title)
    original = slugify title
    attempt = original.dup
    
    attempts = 1
    while Article.exists?(:slug => attempt) and attempts < 100 # failsafe against infinite looping
      attempts += 1
      attempt = "#{original}-#{attempts}"
    end
    attempt
  end
  
  def self.slugify(title)
    title.gsub(/'/, '').gsub(/[^\w\d]+/, '-').gsub(/^-/, '').gsub(/-$/, '').downcase
  end
  
  # until I figure out foreign keys properly
  def comments
    Comment.all :conditions => {:article_slug => slug}
  end
  
end


class Comment
  include MongoMapper::Document
  
  key :article_slug, String, :required => true, :index => true
  key :author_name, String, :index => true
  key :body, String
  
  ensure_index :imported_at
  ensure_index :source
  ensure_index :hidden
  
  timestamps!
  
  # until I figure out foreign keys properly
  def article
    Article.find_by_slug article_slug
  end
end