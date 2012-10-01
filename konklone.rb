#!/usr/bin/env ruby

require './config/environment'


# sinatra-specific config

require 'sinatra/content_for'
require 'sinatra/flash'

set :views, 'app/views'
set :public_folder, 'public'
set :sessions, true

# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "./config/environment.rb"
  config.also_reload "./konklone.rb"
  config.also_reload "./app/models/*.rb"
  config.also_reload "./app/controllers/*.rb"
  config.also_reload "./app/helpers.rb"
end


# extra controllers and helpers

Dir.glob("./app/controllers/*.rb").each {|filename| load filename}
require './app/helpers'
require 'padrino-helpers'
helpers Padrino::Helpers


# base controller

get '/' do
  posts, page = paginate 10, Post.visible.channel("blog").desc(:published_at)
  erb :index, locals: {posts: posts, per_page: 10, page: page, channel: "blog"}
end

get '/ideas' do
  posts, page = paginate 20, Post.visible.channel("idea").desc(:published_at)
  erb :index, locals: {posts: posts, per_page: 10, page: page, channel: "idea"}
end

get '/post/:slug/?' do
  unless post = Post.visible.channel("blog").where(slug: params[:slug]).first
    # fallback for legacy URLs
    post = Post.visible.where(:import_source => "blog3", :import_id => params[:slug].to_i).first
  end

  raise Sinatra::NotFound unless post
  
  erb :post, locals: {post: post, new_comment: nil}
end

get '/idea/:slug/?' do
  post = Post.visible.channel("idea").where(slug: params[:slug]).first
  raise Sinatra::NotFound unless post
  erb :post, locals: {post: post, new_comment: nil}
end

post '/post/:slug/comments' do
  redirect '/' unless params[:comment].present?
  raise Sinatra::NotFound unless post = Post.visible.where(slug: params[:slug]).first
  
  comment = post.comments.build params[:comment]
  comment.ip = get_ip

  if config[:site][:check_spam]
    # not saved, used only for spam checking
    comment.user_agent = request.env['HTTP_USER_AGENT']
    comment.referrer = request.referer unless request.referer == "/"
    
    comment.flagged = comment.spam?
  end
  
  if comment.save
    if comment.flagged
      halt 500, "500 Server Error"
    else
      redirect "#{post_path post}#comment-#{comment.id}"
    end
  else
    erb :post, :locals => {:post => post, :new_comment => comment}
  end
end


# RSS feeds

get /\/(?:unburned-)?rss.xml$/ do
  headers['Content-Type'] = 'application/rss+xml'
  
  posts = Post.visible.desc(:published_at).limit(20).to_a
  erb :rss, :locals => {:site => config[:site], :posts => posts}, :layout => false
end

get '/comments.xml' do
  headers['Content-Type'] = 'application/rss+xml'
  
  comments = Comment.visible.desc(:created_at).limit(20).to_a
  erb :comments, :locals => {:site => config[:site], :comments => comments}, :layout => false
end