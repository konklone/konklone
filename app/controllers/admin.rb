before '/admin/*' do
  if ["", "login", "key/login", "logout"].include?(params[:splat].first)
    pass
  elsif params[:splat].first =~ /^preview/
    pass
  else
    halt 404 unless admin?
  end
end


get %r{/admin/posts/(all|published|drafts|flagged)} do
  # explicitly remove the public default scope in the admin area
  posts = Post.desc :created_at

  filter = params[:captures].first

  posts = posts.visible if filter == "published"
  posts = posts.drafts if filter == "drafts"
  posts = posts.flagged if filter == "flagged"

  posts = posts.tagged(params[:tag]) if params[:tag]

  if params[:q].present?
    posts = posts.admin_search params[:q]
  end

  erb :"admin/posts", layout: :"admin/layout", locals: {posts: posts, filter: filter}
end

get '/admin/posts/new' do
  erb :"admin/new", layout: :"admin/layout"
end

post '/admin/posts' do
  post = Post.new params[:post]
  post.save!
  redirect "/admin/post/#{post.slug}"
end

get '/admin/post/:slug' do
  post = Post.find_by_slug! params[:slug]
  raise Sinatra::NotFound unless post

  erb :"admin/post", layout: :"admin/layout", locals: {post: post}
end

put '/admin/post/:slug' do
  post = Post.find_by_slug! params[:slug]
  raise Sinatra::NotFound unless post

  # have to split the tag string myself
  params[:post]['tags'] = (params[:post]['tags'] || []).split /, ?/

  post.attributes = params[:post]

  # a manual slug override
  if params[:post]['slug'].present? and (params[:post]['slug'] != params[:slug])
    # have to check manually if slug is available
    if Post.where(_slugs: params[:post]['slug']).count == 0
      post.slugs << params[:post]['slug']
    end
  end

  # the toggle buttons also store any changes made to the post
  if ["Publish", "Republish"].include?(params[:submit])
    post.published_at ||= Time.now # don't overwrite this if it was published once already
    post.draft = false
  elsif params[:submit] == "Unpublish"
    post.draft = true
  elsif params[:submit] == "Make public"
    post.private = false
  elsif params[:submit] == "Make private"
    post.private = true

  # to be killed after audit
  elsif params[:submit] == "Flag"
    post.flagged = true
  elsif params[:submit] == "Un-flag"
    post.flagged = false
  end

  if post.save
    redirect "/admin/post/#{post.slug}"
  else
    erb :"admin/post", layout: :"admin/layout", locals: {post: post}
  end
end

delete '/admin/post/:slug' do
  post = Post.find_by_slug! params[:slug]
  raise Sinatra::NotFound unless post

  post.destroy
  flash[:success] = "Deleted post with slug #{post.slug}."

  redirect "/admin/posts/published"
end

get '/admin/preview/:id' do
  # we do our own admin check - allow it for draft posts, but not private posts
  post = Post.find params[:id]
  raise Sinatra::NotFound unless post

  if post.private?
    halt 404 unless admin?
  end

  erb :post, locals: {
    post: post, 
    preview: true
  }
end

get "/admin/?" do
  if admin?
    redirect '/admin/posts/published'
  else
    erb :"admin/login", layout: :"admin/layout", locals: {message: nil}
  end
end

post '/admin/login' do
  if params[:password] == Environment.config['admin']['password']

    session[:admin] = true
    redirect '/admin/posts/published'
  else
    erb :"admin/login", layout: :"admin/layout", locals: {message: "Invalid credentials."}
  end
end

get '/admin/logout' do
  session[:admin] = false
  redirect '/admin'
end
