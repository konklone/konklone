before '/admin/*' do
  if ["login", "logout"].include?(params[:captures].first)
    pass
  elsif params[:captures].first =~ /^preview/
    pass
  else
    halt 404 unless admin?
  end
end

get '/admin' do
  if admin?
    redirect '/admin/posts/published'
  else
    erb :"admin/login", layout: :"admin/layout", locals: {message: nil}
  end
end

post '/admin/login' do
  if params[:password] == config[:admin][:password]
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

get %r{^/admin/posts/(all|published|drafts|flagged)$} do
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

  # BEFORE AFFECTING POST: snap a new version if asked
  if params[:new_version].present?
    post.snap_version params[:new_version]
  end

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

# post preview page (doesn't work for pages with iframes...)
post '/admin/preview' do
  erb :preview, locals: {
    title: params[:title],
    body: params[:body],
    footer: params[:footer]
  }
end

get '/admin/preview/:id' do
  # we do our own admin check - allow it for draft posts, but not private posts
  post = Post.find params[:id]
  raise Sinatra::NotFound unless post

  unless post.draft?
    halt 404 unless admin?
  end

  comments = post.comments.visible.asc(:created_at).to_a

  if params[:version]
    version = post.versions[params[:version].to_i]
    erb :preview, locals: {
      title: version['title'],
      footer: version['footer'],
      body: version['body'],
      version: version,
      comments: comments
    }
  else
    erb :post, locals: {post: post, comments: comments}
  end
end

# list of non-spam comments
get '/admin/comments' do
  per_page = (params[:per_page] || 20).to_i
  comments, page = paginate per_page, Comment.desc(:created_at).where(flagged: false)

  erb :"admin/comments", layout: :"admin/layout", locals: {
    comments: comments,
    flagged: false,
    page: page,
    per_page: per_page
  }
end

# list of comments marked as spam
get '/admin/comments/flagged' do
  per_page = (params[:per_page] || 100).to_i
  comments, page = paginate per_page, Comment.desc(:created_at).where(flagged: true)
  erb :"admin/comments", layout: :"admin/layout", locals: {
    comments: comments,
    flagged: true,
    page: page,
    per_page: per_page
  }
end

delete '/admin/comments/flagged/clear' do
  Comment.flagged.delete_all
  redirect "/admin/comments/flagged"
end

# edit form for a comment
get '/admin/comment/:id' do
  raise Sinatra::NotFound unless comment = Comment.find(params[:id])

  erb :"admin/comment", layout: :"admin/layout", locals: {comment: comment}
end

# update a comment
put '/admin/comment/:id' do
  raise Sinatra::NotFound unless comment = Comment.find(params[:id])

  mine = (params[:comment]['mine'] == "on")
  tell_akismet = (params['tell_akismet'] == "on")

  comment.attributes = params[:comment]
  comment.ip = params[:comment]['ip']
  comment.mine = mine

  if params[:submit] == "Hide"
    comment.hidden = true
  elsif params[:submit] == "Show"
    comment.hidden = false
  elsif params[:submit] == "Ham!"
    comment.flagged = false
    comment.ham! if tell_akismet
  elsif params[:submit] == "Spam!"
    comment.flagged = true
    comment.spam! if tell_akismet
  end

  if comment.save
    redirect "/admin/comment/#{comment._id}"
  else
    erb :"admin/comment", layout: :"admin/layout", locals: {comment: comment}
  end
end

delete '/admin/comment/:id' do
  raise Sinatra::NotFound unless comment = Comment.find(params[:id])

  comment.destroy
  flash[:success] = "Deleted comment with ID #{comment.id}."

  # redirect "/admin/comments/published"
  redirect params[:redirect_to]
end

put '/admin/comments' do
  comment_ids = params[:comment_ids] || []
  tell_akismet = (params['tell_akismet'] == "on")

  comment_ids.each do |id|
    comment = Comment.find id
    next unless comment

    if params[:submit] == "Hide"
      comment.hidden = true
    elsif params[:submit] == "Show"
      comment.hidden = false
    elsif params[:submit] == "Ham!"
      comment.flagged = false
      comment.ham! if tell_akismet
    elsif params[:submit] == "Spam!"
      comment.flagged = true
      comment.spam! if tell_akismet
    end

    comment.save!
  end

  flash[:success] = "Updated #{comment_ids.size} comments."
  redirect params[:redirect_to]
end