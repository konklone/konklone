before '/admin/[^(login|logout)]*' do
  halt(401, "Not authorized") unless admin?
end

# login form
get '/admin/?' do
  if admin?
    redirect '/admin/posts/'
  else
    erb :"admin/login", :layout => :"admin/layout", :locals => {:message => nil}
  end
end

# log in
post '/admin/login' do
  if (params[:username] == config[:admin][:username]) and (params[:password] == config[:admin][:password])
    session[:admin] = true
    redirect '/admin/posts/'
  else
    erb :"admin/login", :layout => :"admin/layout", :locals => {:message => "Invalid credentials."}
  end
end

# log out
get '/admin/logout/?' do
  session[:admin] = false
  redirect '/admin/'
end

# list all posts 
get '/admin/posts/?' do
  posts = Post.admin
  
  # filtering
  if params[:q].present?
    posts = posts.admin_search params[:q]
  end
  
  posts, page = paginate 20, posts
  erb :"admin/posts", :layout => :"admin/layout", :locals => {:posts => posts, :page => page, :per_page => 20}
end

# form for creating a new post
get '/admin/posts/new/?' do
  erb :"admin/new", :layout => :"admin/layout"
end

# create a new post
post '/admin/posts/?' do
  post = Post.new params[:post]
  post.save! # should be no reason for failure
  redirect "/admin/post/#{post.slug}"
end

# main edit form for a post
get '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  # if coming from a list, figure out the next and previous post from that list
  older_post = nil
  newer_post = nil
  if params[:offset].present?
    
    posts = Post.admin
    if params[:q].present?
      posts = posts.admin_search(params[:q])
    end
    
    offset = params[:offset].to_i
    
    newer_post = posts.skip(offset - 1).first if offset > 0
    older_post = posts.skip(offset + 1).first
  end
  
  erb :"admin/post", :layout => :"admin/layout", :locals => {:post => post, :newer_post => newer_post, :older_post => older_post, :offset => offset}
end

# update a post
put '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  if params[:submit] == "Update"
    params[:post]['tags'] = (params[:post]['tags'] || []).split /, ?/
    params[:post]['display_title'] = (params[:post]['display_title'] == "on")
    
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
  end
  
  if post.save
    redirect "/admin/post/#{post.slug}"
  else
    erb :"admin/post", :locals => {:post => post}
  end
end

delete '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  post.destroy
  flash[:success] = "Deleted post with slug #{post.slug}."
  
  redirect "/admin/posts/"
end

# post preview page (URL requires guessing db ID)
get '/admin/post/:id/preview/?' do
  post = Post.where(:_id => BSON::ObjectId(params[:id])).first
  raise Sinatra::NotFound unless post
  
  erb :post, :locals => {:post => post}
end

# list of non-spam comments
get '/admin/comments/?' do
  comments, page = paginate 20, Comment.desc(:created_at).where(:flagged => false)
  
  erb :"admin/comments", :layout => :"admin/layout", :locals => {:comments => comments, :flagged => false, :page => page, :per_page => 20}
end

# list of comments marked as spam
get '/admin/comments/flagged/?' do
  comments, page = paginate 20, Comment.desc(:created_at).where(:flagged => true)
  erb :"admin/comments", :layout => :"admin/layout", :locals => {:comments => comments, :flagged => true, :page => page, :per_page => 20}
end

delete '/admin/comments/flagged/clear/?' do
  Comment.flagged.delete_all
  redirect "/admin/comments/flagged/"
end

# edit form for a comment
get '/admin/comment/:id' do
  comment = Comment.where(:_id => BSON::ObjectId(params[:id])).first
  raise Sinatra::NotFound unless comment
  
  erb :"admin/comment", :layout => :"admin/layout", :locals => {:comment => comment}
end

# update a comment
put '/admin/comment/:id' do
  comment = Comment.where(:_id => BSON::ObjectId(params[:id])).first
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
    erb :"admin/comment", :layout => :"admin/layout", :locals => {:comment => comment}
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