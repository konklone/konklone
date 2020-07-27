#!/usr/bin/env ruby

require './config/environment'

get '/' do
  erb :index, layout: :layout_home
end

get '/blog' do
  posts = Post.visible.here.desc(:published_at)
  erb :blog, locals: {posts: posts}
end

get '/projects' do
  erb :projects
end

# if I don't support an accented é, why did I bothér
get /\/(resume|r%C3%A9sum%C3%A9)/i do
  erb :resume, locals: {independent: true}
end

get '/post/:slug/?' do
  post = Post.visible.find_by_slug! params[:slug]
  raise Sinatra::NotFound unless post
  redirect(post.redirect_url, 301) if post.redirect_url.present?

  erb :post, locals: {post: post}
end

get '/error' do
  raise Exception.new("YOU'RE KILLING MEEEEE")
end

error do
  exception = env['sinatra.error']

  cleaned = params
  [:password, "password"].each {|p| cleaned.delete p }

  request = {
    method: env['REQUEST_METHOD'],
    url: "#{Environment.config['site']['root']}#{env['REQUEST_URI']}",
    params: cleaned.inspect,
    user_agent: env['HTTP_USER_AGENT']
  }

  Email.exception(exception, request: request)
  erb :"500"
end


get '/rss.xml' do
  headers['Content-Type'] = 'application/rss+xml'

  posts = Post.visible.here.desc(:published_at).limit(20).to_a
  erb :rss, locals: {site: Environment.config['site'], posts: posts}, layout: false
end
