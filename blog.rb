#!/usr/bin/env ruby

require 'config/environment'
require 'helpers'

set :views, 'views'
set :public, 'public'

get '/' do
  erb :index, :locals => {:posts => Post.visible.desc(:published_at).limit(10)}
end

get '/post/:slug' do
  post = Post.visible.where(:slug => params[:slug]).first
  if post
    erb :post, :locals => {:post => post}
  else
    head 404
  end
end