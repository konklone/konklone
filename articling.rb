#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

get '/' do
  Article.all.map(&:title).join '\n<br/>'
end


class Article
  include MongoMapper::Document
  
  key :slug, String, :required => true, :index => true
  
  timestamps!
end


configure do
  MongoMapper.database = 'articling'
  MongoMapper.ensure_indexes!
end