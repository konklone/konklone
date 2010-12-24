require 'rdiscount'

helpers do
  
  def post_path(post)
    "/post/#{post.slug}"
  end
  
  def comment_path(post)
    "#{post_path post}/comments"
  end
  
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
  def short_datetime(time)
    time.strftime "%Y-%m-%d"
  end
  
  def long_datetime(time)
    time.xmlschema
  end
  
  def short_date(time)
    time.strftime "%b #{time.day}" # remove 0-prefix
  end
  
  def long_date(time)
    time.strftime "%B #{time.day}, %Y" # remove 0-prefix
  end
  
  def rss_date(time)
    time.strftime "%a, %d %b %Y %H:%M:%S %T"
  end
  
  def comment_time(time)
    # Aug 21, 12:03pm
    meridian = time.strftime "%p"
    hour = time.strftime "%I"
    day = time.strftime "%d"
    time.strftime "%b #{day.to_i}, #{hour.to_i}:%M#{meridian.downcase}"
  end
  
  def post_body(body)
    RDiscount.new(body).to_html
  end
  
  def comment_body(body)
    RDiscount.new(body, :filter_html).to_html
  end
  
end