#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

get '/' do
  Article.all(:order => "created_at ASC").map do |article|
    "#{article.title}:\n<br/>#{article.body}"
  end.join "\n\n<br/><br/>"
end


class Article
  include MongoMapper::Document
  
  key :slug, String, :required => true, :index => true
  
  ensure_index :tags
  ensure_index :source
  ensure_index :private
  ensure_index :imported_at
  
  timestamps!
end


configure do
  MongoMapper.database = 'articling'
  MongoMapper.ensure_indexes!
end