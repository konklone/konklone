require 'rdiscount'

helpers do
  
  def admin?
    session[:admin] == true
  end
  
  def pagination(per_page)
    page = params[:page].to_i || 1
    page = 1 if page < 1
    {:page => page, :per_page => per_page}
  end
  
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
  
  def post_body(post)
    render_songs RDiscount.new(post.body).to_html, post.slug
  end
  
  def comment_body(body)
    RDiscount.new(body, :filter_html, :autolinks).to_html
  end
  
  def meta_description(post)
    post_body(post).gsub "\"", "&quot;"
  end
  
  def form_escape(string)
    string.gsub "\"", "&quot;"
  end
  
  def render_songs(body, slug)
    body.gsub /\[song "([^"]+)"\].*?\[name\](.*?)\[\/name\].*?\[by\](.*?)\[\/by\].*?\[\/song\]/im do
      partial :song, :locals => {
        :filename => $1,
        :name => $2,
        :by => $3,
        :slug => slug
      }
    end
  end
end

# stolen from http://github.com/cschneid/irclogger/blob/master/lib/partials.rb
#   and made a lot more robust by me
# this implementation uses erb by default. if you want to use any other template mechanism
#   then replace `erb` on line 13 and line 17 with `haml` or whatever 
module Sinatra::Partials
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << erb(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      erb(:"#{template}", options)
    end
  end
end

helpers Sinatra::Partials