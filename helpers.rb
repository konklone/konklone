require 'rdiscount'

helpers do
  
  def post_url(post)
    "/post/#{post.slug}"
  end
  
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
  def post_display_time(post)
    time = post.published_at
    time.strftime "%b #{time.day}" # remove 0-prefix
  end
  
  def post_body(body)
    RDiscount.new(body).to_html
  end
  
end