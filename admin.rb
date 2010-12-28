
get '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
  erb :"admin/post", :layout => :"admin/layout", :locals => {:post => post}
end

put '/admin/post/:slug' do
  post = Post.where(:slug => params[:slug]).first
  raise Sinatra::NotFound unless post
  
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