#!/usr/bin/env ruby

require './config/environment'


# log google hits in a database, to understand behavior better

before do
  @start_time = Time.now
end

after do
  Event.google!(env, @start_time) if @start_time and google?
end


# base controller

get '/' do
  per_page = 30
  posts, page = paginate per_page, Post.visible.here.desc(:published_at)
  erb :index, locals: {posts: posts, per_page: per_page, page: page}
end

get '/projects' do
  erb :projects
end

get '/blackout' do
  blackout = Environment.blackouts.last
  page = File.read "app/views/blackout/#{blackout[:file]}.html"
  erb :blackout, locals: {page: page, current_blackout: blackout}
end

get '/blackout/:blackout' do
  id = params[:blackout][0..3].to_i
  blackout = Environment.blackouts[id-1]

  page = File.read "app/views/blackout/#{blackout[:file]}.html"
  erb :blackout, locals: {page: page, current_blackout: blackout}
end

# if I don't support an accented é, why did I bothér
get /\/(resume|r%C3%A9sum%C3%A9)/i do
  erb :resume, locals: {resume: true}
end

get '/post/:slug/?' do
  post = Post.visible.find_by_slug! params[:slug]
  raise Sinatra::NotFound unless post
  redirect(post.redirect_url, 301) if post.redirect_url.present?

  comments = post.comments.visible.asc(:created_at).to_a

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
    redirect "#{post_path post}#comment-#{comment.id}"
  else
    comments = post.comments.visible.asc(:created_at).to_a
    erb :post, locals: {post: post, new_comment: comment, comments: comments}
  end
end

# ajax endpoint for subscribe-by-email form
post '/subscribe' do
  email = params[:email].strip

  subscriber = Subscriber.find_or_initialize_by email: email
  new_subscriber = subscriber.new_record?
  # TODO: handle unsubscribed user resubscribing
  # TODO: handle currently subscribed user
  # TODO: store event on subscribe, send email to admin

  if subscriber.save
    if new_subscriber
      Email.new_subscriber subscriber
    end

    status 201
  else
    status 500
  end
end

# TODO: confirm email endpoint
  # lookup user
  # mark user as confirmed (confirmed_at)
  # plain template saying they're confirmed (new view)

# TODO: unsubscribe endpoint


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

  posts = Post.visible.here.desc(:published_at).limit(20).to_a
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