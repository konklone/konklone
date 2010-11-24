#!/usr/bin/env ruby

require 'config/environment'

# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "config/environment.rb"
  config.also_reload "models.rb"
end


set :logging, false

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
  include Mongoid::Slug
  
  field :source
  field :title
  field :body
  field :article_type
  field :tags, :type => Array
  field :private, :type => Boolean
  field :imported_at, :type => DateTime
  
  slug :title
  
  index :slug
  index :article_type
  index :tags
  index :source
  index :private
  index :imported_at
  
  validates_uniqueness_of :slug, :allow_nil => true
  
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