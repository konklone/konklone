get '/admin/posts/?' do
  posts = Post.desc(:created_at).paginate(pagination(20))
  erb :"admin/posts", :layout => :"admin/layout", :locals => {:posts => posts}
end

get '/admin/posts/new/?' do
  erb :"admin/new", :layout => :"admin/layout"
end

post '/admin/posts/?' do
  post = Post.new params[:post]
  post.save! # should be no reason for failure
  redirect "/admin/post/#{post.slug}"
end

get '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  erb :"admin/post", :layout => :"admin/layout", :locals => {:post => post}
end

put '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  params[:post]['tags'] = (params[:post]['tags'] || []).split /, ?/
  params[:post]['display_title'] = (params[:post]['display_title'] == "on")
  
  post.attributes = params[:post]
  
  if params[:submit] == "Publish"
    post.published_at = Time.now
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

get '/admin/comments/?' do
  comments = Comment.desc(:created_at).where(:flagged => false).all.paginate(pagination(20))
  erb :"admin/comments", :layout => :"admin/layout", :locals => {:comments => comments, :flagged => false}
end

get '/admin/comments/flagged/?' do
  comments = Comment.desc(:created_at).where(:flagged => true).all.paginate(pagination(100))
  erb :"admin/comments", :layout => :"admin/layout", :locals => {:comments => comments, :flagged => true}
end

get '/admin/comment/:id' do
  comment = Comment.where(:_id => BSON::ObjectId(params[:id])).first
  raise Sinatra::NotFound unless comment
  
  erb :"admin/comment", :layout => :"admin/layout", :locals => {:comment => comment}
end

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