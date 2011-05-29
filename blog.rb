#!/usr/bin/env ruby

require 'config/environment'
require 'sinatra/content_for'
require 'sinatra/flash'

set :views, 'views'
set :public, 'public'
set :sessions, true

require 'helpers'
require 'admin'


get '/' do
  posts, page = paginate 10, Post.visible.desc(:published_at)
  erb :index, :locals => {:posts => posts, :per_page => 10, :page => page}
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
  comment.ip = get_ip

  if config[:site][:check_spam]
    # not saved, used only for spam checking
    comment.user_agent = request.env['HTTP_USER_AGENT']
    comment.referrer = request.referer unless request.referer == "/"
    
    comment.flagged = comment.spam?
  end
  
  if comment.save
    if comment.flagged
      throw :halt, [500, "500 Server Error"]
    else
      redirect "#{post_path(post)}#comment-#{comment.id}"
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