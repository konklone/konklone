#!/usr/bin/env ruby

require 'config/environment'
require 'sinatra/content_for'
require 'helpers'

set :views, 'views'
set :public, 'public'


get '/' do
  erb :index, :locals => {:posts => Post.visible.desc(:published_at).paginate(pagination)}
end

get '/post/:slug/?' do
  unless post = Post.visible.where(:slug => params[:slug]).first
    # fallback for legacy URLs
    post = Post.visible.where(:import_source => "blog3", :import_id => params[:slug].to_i).first
  end
  raise Sinatra::NotFound unless post
  
  erb :post, :locals => {:post => post, :new_comment => nil}
end

post '/post/:slug/comments' do
  redirect '/' unless params[:comment].present?
  raise Sinatra::NotFound unless post = Post.visible.where(:slug => params[:slug]).first
  
  comment = post.comments.build params[:comment]
  comment.ip = request.env['REMOTE_ADDR']

  if production?
    # not saved, used only for spam checking
    comment.user_agent = request.env['HTTP_USER_AGENT']
    comment.referrer = request.referer unless request.referer == "/"
    
    comment.flagged = comment.spam?
  end
  
  if comment.save
    redirect "#{post_path(post)}#comment-#{comment.id}"
  else
    erb :post, :locals => {:post => post, :new_comment => comment}
  end
end


# RSS feeds

get /\/(?:unburned-)?rss.xml$/ do
  headers['Content-Type'] = 'application/rss+xml'
  erb :rss, :locals => {:site => config[:site], :posts => Post.visible.desc(:published_at).limit(20).to_a}, :layout => false
end

get '/comments.xml' do
  headers['Content-Type'] = 'application/rss+xml'
  erb :comments, :locals => {:site => config[:site], :comments => Comment.visible.desc(:created_at).limit(20).to_a}, :layout => false
end