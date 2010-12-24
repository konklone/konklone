#!/usr/bin/env ruby

require 'config/environment'
require 'helpers'

set :views, 'views'
set :public, 'public'

get '/' do
  erb :index, :locals => {:posts => Post.visible.desc(:published_at).limit(10)}
end

get '/post/:slug/?' do
  raise Sinatra::NotFound unless post = Post.visible.where(:slug => params[:slug]).first
  
  erb :post, :locals => {:post => post, :new_comment => nil}
end

post '/post/:slug/comments' do
  redirect '/' unless params[:comment].present?
  raise Sinatra::NotFound unless post = Post.visible.where(:slug => params[:slug]).first
  
  comment = post.comments.build params[:comment]
  comment.ip = request.env['REMOTE_ADDR']
  
  if comment.save
    redirect "#{post_path(post)}#comment-#{comment.id}"
  else
    erb :post, :locals => {:post => post, :new_comment => comment}
  end
end

get /\/(?:unburned-)?rss.xml$/ do
  headers['Content-Type'] = 'application/rss+xml'
  erb :rss, :locals => {:site => config[:site], :posts => Post.visible.desc(:published_at).limit(20)}, :layout => false
end

get '/comments.xml' do
  headers['Content-Type'] = 'application/rss+xml'
  erb :comments, :locals => {:site => config[:site], :comments => Comment.visible.desc(:created_at).limit(20)}, :layout => false
end