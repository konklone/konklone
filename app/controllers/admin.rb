before '/admin/[^(login|logout)]*' do
  halt(401, "Not authorized") unless admin?
end

get '/admin/?' do
  if admin?
    redirect '/admin/posts/published'
  else
    erb :"admin/login", layout: :"admin/layout", locals: {message: nil}
  end
end

post '/admin/login' do
  if (params[:username] == config[:admin][:username]) and (params[:password] == config[:admin][:password])
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

get %r{^/admin/posts/(all|published|drafts|private|flagged)$} do
  posts = Post.desc :created_at

  filter = params[:captures].first

  posts = posts.visible if filter == "published"
  posts = posts.private if filter == "private"
  posts = posts.drafts if filter == "drafts"
  posts = posts.flagged if filter == "flagged"
  
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
  post = Post.where(slug: params[:slug]).first
  raise Sinatra::NotFound unless post
  
  erb :"admin/post", layout: :"admin/layout", locals: {post: post}
end

put '/admin/post/:slug' do
  post = Post.where(slug: params[:slug]).first
  raise Sinatra::NotFound unless post
  
  if params[:submit] == "Update"
    params[:post]['tags'] = (params[:post]['tags'] || []).split /, ?/
    
    post.attributes = params[:post]

    if params[:post]['slug']
      post.slug = params[:post]['slug']
    end
  
  # all the toggle buttons ignore any changes made to the form
  elsif ["Publish", "Republish"].include?(params[:submit])
    post.published_at ||= Time.now # don't overwrite this if it was published once already
    post.draft = false
  elsif params[:submit] == "Unpublish"
    post.draft = true
  elsif params[:submit] == "Make public"
    post.private = false
  elsif params[:submit] == "Make private"
    post.private = true
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
  post = Post.where(slug: params[:slug]).first
  raise Sinatra::NotFound unless post
  
  post.destroy
  flash[:success] = "Deleted post with slug #{post.slug}."
  
  redirect "/admin/posts/published"
end

# post preview page (URL requires guessing db ID)
get '/admin/post/:id/preview' do
  post = Post.where(:_id => BSON::ObjectId(params[:id])).first
  raise Sinatra::NotFound unless post
  
  erb :post, locals: {post: post}
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
  comment = Comment.where(_id: BSON::ObjectId(params[:id])).first
  raise Sinatra::NotFound unless comment
  
  erb :"admin/comment", layout: :"admin/layout", locals: {comment: comment}
end

# update a comment
put '/admin/comment/:id' do
  comment = Comment.where(_id: BSON::ObjectId(params[:id])).first
  raise Sinatra::NotFound unless comment
  
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