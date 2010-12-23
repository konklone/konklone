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
    redirect post_path(post)
  else
    erb :post, :locals => {:post => post, :new_comment => comment}
  end
end