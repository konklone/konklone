#!/usr/bin/env ruby

require './config/environment'


# log google hits in a database, to understand behavior better

before do
  @start_time = Time.now
end

after do
  Event.google!(env, @start_time) if google?
end


# base controller

get '/' do
  posts, page = paginate 20, Post.visible.desc(:published_at)
  erb :index, locals: {posts: posts, per_page: 10, page: page}
end

get '/projects' do
  erb :projects
end

get '/post/:slug/?' do
  post = Post.visible.find_by_slug! params[:slug]
  raise Sinatra::NotFound unless post

  comments = post.comments.visible.asc(:created_at).to_a

  # nginx will serve anything cached
  # Environment.cache!(post.slug, rendered) if config[:site]['cache_enabled']

  erb :post, locals: {post: post, new_comment: nil, comments: comments}
end

post '/comments/post/:slug' do
  redirect '/' unless params[:comment].present?
  raise Sinatra::NotFound unless post = Post.visible.find_by_slug!(params[:slug])

  comment = post.comments.build params[:comment]
  comment.ip = get_ip

  if config[:site][:check_spam]
    # not saved, used only for spam checking
    comment.user_agent = request.env['HTTP_USER_AGENT']
    comment.referrer = request.referer unless request.referer == "/"

    comment.flagged = comment.spam?
  end

  saved = false
  begin
    saved = comment.save
  rescue ArgumentError => ex
    # broken utf-8, get out the hatchet (don't want to use
    # this unless I must, as it kills valid unicode too)

    # if this proves too blunt, then the next solution would be:
    # .force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
    # as in http://stackoverflow.com/questions/9607554/ruby-invalid-byte-sequence-in-utf-8
    # which works, but it's not clear to me whether it properly preserves real unicode.

    ['body', 'author', 'author_url', 'author_email'].each do |field|
      comment[field].encode!('utf-8', 'binary', invalid: :replace, undef: :replace, replace: "") if comment[field]
    end
    saved = comment.save # if it still will crash, let it crash
  end

  if saved
    if comment.flagged and (post.published_at > 2.weeks.ago)
      Email.flagged_comment comment
    end

    redirect "#{post_path post}#comment-#{comment.id}"
  else
    comments = post.comments.visible.asc(:created_at).to_a
    erb :post, locals: {post: post, new_comment: comment, comments: comments}
  end
end

get '/error' do
  raise Exception.new("YOU'RE KILLING MEEEEE")
end

error do
  exception = env['sinatra.error']

  request = {
    method: env['REQUEST_METHOD'],
    url: "#{config[:site][:root]}#{env['REQUEST_URI']}",
    params: params.inspect,
    user_agent: env['HTTP_USER_AGENT']
  }

  Email.exception(exception, request: request)
  erb :"500"
end


get '/rss.xml' do
  headers['Content-Type'] = 'application/rss+xml'

  posts = Post.visible.desc(:published_at).limit(20).to_a
  erb :rss, locals: {site: config[:site], posts: posts}, layout: false
end

get '/comments.xml' do
  headers['Content-Type'] = 'application/rss+xml'

  comments = Comment.visible.desc(:created_at).limit(20).to_a
  erb :comments, locals: {site: config[:site], comments: comments}, layout: false
end

helpers do
  def google?
    request.env['HTTP_USER_AGENT']["Googlebot"] if request.env['HTTP_USER_AGENT']
  end
end