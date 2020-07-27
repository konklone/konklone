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

  # handled a bit differently
  # post.github_last_message = params[:save_message]

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
    # on first publish, generate a github URL if it's blank
    # if !post.published_at and post.github.blank?
    #   post.generate_github_url
    # end

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
    # if post.was_synced
    #   flash[:success] = "Saved, and synced to Github."
    # else
    #   flash[:success] = "Saved, but not synced to Github."
    # end

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

  # comments = post.comments.visible.asc(:created_at).to_a

  erb :post, locals: {
    post: post, 
    # comments: comments,
    preview: true
  }
end

# # list of non-spam comments
# get '/admin/comments' do
#   per_page = (params[:per_page] || 20).to_i
#   comments, page = paginate per_page, Comment.desc(:created_at).where(flagged: false)

#   erb :"admin/comments", layout: :"admin/layout", locals: {
#     comments: comments,
#     flagged: false,
#     page: page,
#     per_page: per_page
#   }
# end

# list of comments marked as spam
# get '/admin/comments/flagged' do
#   per_page = (params[:per_page] || 100).to_i
#   comments, page = paginate per_page, Comment.desc(:created_at).where(flagged: true)
#   erb :"admin/comments", layout: :"admin/layout", locals: {
#     comments: comments,
#     flagged: true,
#     page: page,
#     per_page: per_page
#   }
# end

# delete '/admin/comments/flagged/clear' do
#   Comment.flagged.delete_all
#   redirect "/admin/comments/flagged"
# end

# # edit form for a comment
# get '/admin/comment/:id' do
#   raise Sinatra::NotFound unless comment = Comment.find(params[:id])

#   erb :"admin/comment", layout: :"admin/layout", locals: {comment: comment}
# end

# update a comment
# put '/admin/comment/:id' do
#   raise Sinatra::NotFound unless comment = Comment.find(params[:id])

#   mine = (params[:comment]['mine'] == "on")
#   tell_akismet = (params['tell_akismet'] == "on")

#   comment.attributes = params[:comment]
#   comment.ip = params[:comment]['ip']
#   comment.mine = mine

#   if params[:submit] == "Hide"
#     comment.hidden = true
#   elsif params[:submit] == "Show"
#     comment.hidden = false
#   elsif params[:submit] == "Ham!"
#     comment.flagged = false
#     comment.ham! if tell_akismet
#   elsif params[:submit] == "Spam!"
#     comment.flagged = true
#     comment.spam! if tell_akismet
#   end

#   if comment.save
#     redirect "/admin/comment/#{comment._id}"
#   else
#     erb :"admin/comment", layout: :"admin/layout", locals: {comment: comment}
#   end
# end

# delete '/admin/comment/:id' do
#   raise Sinatra::NotFound unless comment = Comment.find(params[:id])

#   comment.destroy
#   flash[:success] = "Deleted comment with ID #{comment.id}."

#   # redirect "/admin/comments/published"
#   redirect params[:redirect_to]
# end

# put '/admin/comments' do
#   comment_ids = params[:comment_ids] || []
#   tell_akismet = (params['tell_akismet'] == "on")

#   comment_ids.each do |id|
#     comment = Comment.find id
#     next unless comment

#     if params[:submit] == "Hide"
#       comment.hidden = true
#     elsif params[:submit] == "Show"
#       comment.hidden = false
#     elsif params[:submit] == "Ham!"
#       comment.flagged = false
#       comment.ham! if tell_akismet
#     elsif params[:submit] == "Spam!"
#       comment.flagged = true
#       comment.spam! if tell_akismet
#     end

#     comment.save!
#   end

#   flash[:success] = "Updated #{comment_ids.size} comments."
#   redirect params[:redirect_to]
# end

get "/admin/?" do
  if admin?
    redirect '/admin/posts/published'
  # elsif half_admin?
  #   redirect '/admin/key/login'
  else
    erb :"admin/login", layout: :"admin/layout", locals: {message: nil}
  end
end

post '/admin/login' do
  if params[:password] == Environment.config['admin']['password']

    # if Device.count > 0
    #   session[:half_admin] = true
    #   redirect '/admin/key/login'
    # else
      session[:admin] = true
      redirect '/admin/posts/published'
    # end
  else
    erb :"admin/login", layout: :"admin/layout", locals: {message: "Invalid credentials."}
  end
end

get '/admin/logout' do
  session[:admin] = false
  redirect '/admin'
end


########################################################
# FIDO U2F support. Using the code and documentation at:
# https://github.com/userbin/ruby-u2f
#
# See the explanation of the original implementation at:
# https://github.com/konklone/konklone.com/pull/144
########################################################

# get '/admin/key/register' do
#   # Generate one for each version of U2F, currently only `U2F_V2`
#   registration_requests = Environment.u2f.registration_requests

#   # Keep challenges around for verification
#   session[:challenges] = registration_requests.map &:challenge

#   # Key handles for all devices registered (to me: which is all of them)
#   devices = Device.all
#   key_handles = devices.map &:key_handle
#   sign_requests = Environment.u2f.authentication_requests key_handles

#   erb :"admin/key_register", layout: :"admin/layout", locals: {
#     registration_requests: registration_requests,
#     sign_requests: sign_requests,
#     devices: devices
#   }
# end

# post '/admin/key/register' do
#   unless (name = params[:name]).present?
#     flash[:failure] = "I need a device name."
#     redirect "/admin/key/register"
#   end

#   begin
#     response = U2F::RegisterResponse.load_from_json params[:response]
#   rescue Exception => exc
#     Email.exception exc, {response: params[:response]}
#     flash[:failure] = "Invalid registration data."
#     redirect "/admin/key/register"
#   end

#   reg = begin
#     Environment.u2f.register!(session[:challenges], response)
#   rescue U2F::Error => exc
#     Email.exception exc
#     nil
#   ensure
#     session.delete :challenges
#   end

#   if reg
#     flash[:success] = "DEVICE REGISTERED. THANK YOU, TOKEN BEARER."

#     Device.create!(
#       certificate: reg.certificate,
#       key_handle:  reg.key_handle,
#       public_key:  reg.public_key,
#       counter:     reg.counter,
#       name: name
#     )
#   else
#     flash[:failure] = "DEVICE NOT REGISTERED. EMAIL SENT WITH YOUR FAILURE."
#   end

#   redirect "/admin/key/register"
# end

# get '/admin/key/login' do
#   unless half_admin?
#     flash[:failure] = "You need to know the password before you get to show the token."
#     redirect "/admin"
#   end

#   key_handles = Device.all.map &:key_handle

#   if key_handles.empty?
#     flash[:failure] = "Weird: no keys registered. Why are you here?"
#     redirect "/admin"
#   end

#   sign_requests = Environment.u2f.authentication_requests key_handles

#   session[:challenges] = sign_requests.map &:challenge

#   erb :"admin/key_login", layout: :"admin/layout", locals: {
#     sign_requests: sign_requests
#   }
# end

# post '/admin/key/login' do
#   unless half_admin?
#     flash[:failure] = "You need to know the password before you get to show the token."
#     redirect "/admin"
#   end

#   response = U2F::SignResponse.load_from_json params[:response]

#   unless device = Device.where(key_handle: response.key_handle).first
#     flash[:failure] = "This device has never been registered."
#     redirect "/admin/key/login"
#   end

#   authenticated = false
#   failure = nil
#   begin
#     Environment.u2f.authenticate!(
#       session[:challenges],
#       response,

#       # database stores base64-encoded version - library needs real binary string
#       Base64.strict_decode64(device.public_key),

#       device.counter
#     )
#     authenticated = true

#   rescue U2F::CounterToLowError => exc
#     Email.exception exc
#     failure = "Your device has gotten out of sync with the server. Your device may have been compromised. You will need to use other means to invalidate this device and re-authorize it or add a new one."
#     nil
#   rescue U2F::Error => exc
#     Email.exception exc
#     failure = "Failed to log in. Try again or something?"
#     nil
#   ensure
#     session.delete :challenges
#   end

#   if authenticated
#     device.update(counter: response.counter)
#     flash[:success] = "WELCOME, TOKEN BEARER."

#     session.delete :half_admin
#     session[:admin] = true

#     redirect "/admin"
#   else
#     flash[:failure] = failure
#     redirect "/admin/key/login"
#   end
# end

# delete "/admin/key/:key_handle" do
#   unless (device = Device.where(key_handle: params[:key_handle]).first)
#     flash[:failure] = "Couldn't find the specified device."
#     redirect "/admin/key/register"
#   end

#   device.delete
#   flash[:success] = "Device \"#{device.name}\" deleted."
#   redirect "/admin/key/register"
# end
