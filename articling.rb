#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

require 'mongoid'

configure do
  Mongoid.database = Mongo::DB.new('articling-mongoid', Mongo::Connection.new)
end


get '/' do
  Article.all(:sort => [:created_at, 1]).map do |article|
    "#{article.title}:\n<br/>#{article.body}"
  end.join "\n\n<br/><br/>"
end

get "/articles.json" do
  Article.all.to_json
end

get "/comments.json" do
  Comment.all.to_json
end


class Article
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :slug, :type => String # required
  field :title, :type => String
  field :body, :type => String
  field :article_type, :type => String
  field :tags, :type => Array
  field :source, :type => String
  field :private, :type => Boolean
  field :imported_at, :type => DateTime
  
  index :slug
  index :article_type
  index :tags
  index :source
  index :private
  index :imported_at
  
  
  def self.slug_for(title)
    original = slugify title
    attempt = original.dup
    
    attempts = 1
    while Article.first(:conditions => {:slug => attempt}) and attempts < 100 # failsafe against infinite looping
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
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :article_slug, :type => String
  field :author_name, :type => String
  field :body, :type => String
  field :imported_at, :type => DateTime
  field :source, :type => String
  field :hidden, :type => Boolean
  
  index :article_slug
  index :author_name
  index :source
  index :hidden
  index :imported_at
  
  
  # until I figure out foreign keys properly
  def article
    Article.first :conditions => {:slug => article_slug}
  end
end