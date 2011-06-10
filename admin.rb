before '/admin/[^(login|logout)]*' do
  throw(:halt, [401, "Not authorized\n"]) unless admin?
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
  # allow filtering
  posts = params[:q].present? ? Post.search(params[:q]) : Post
  
  posts, page = paginate 20, posts.desc(:created_at)
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
  
  erb :"admin/post", :layout => :"admin/layout", :locals => {:post => post}
end

# update a post
put '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  if params[:submit] == "Update"
    params[:post]['tags'] = (params[:post]['tags'] || []).split /, ?/
    params[:post]['display_title'] = (params[:post]['display_title'] == "on")
    
    post.attributes = params[:post]
  
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
  
  params[:comment]['mine'] = (params[:comment]['mine'] == "on")
  
  comment.attributes = params[:comment]
  comment.ip = params[:comment]['ip']
  comment.mine = params[:comment]['mine']
  
  if params[:submit] == "Hide"
    comment.hidden = true
  elsif params[:submit] == "Show"
    comment.hidden = false
  end
  
  if comment.save
    redirect "/admin/comment/#{comment._id}"
  else
    erb :"admin/comment", :layout => :"admin/layout", :locals => {:comment => comment}
  end
end