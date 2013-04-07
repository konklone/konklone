# encoding: utf-8

module Helpers
  module General

    # don't give me empty strings
    def content_from(symbol)
      content = yield_content symbol

      # not sure why yield_content returns US-ASCII
      content.force_encoding("UTF-8") if content 
      
      if content.present?
        content
      else
        nil
      end
    end
    
    def get_ip
      forwarded = request.env['HTTP_X_FORWARDED_FOR']
      forwarded.present? ? forwarded.split(',').first : nil
    end
    
    def admin?
      session[:admin] == true
    end

    def paginate(per_page, criteria)
      page = (params[:page]).to_i || 1
      page = 1 if page < 1
      
      [
        criteria.skip((page-1) * per_page).limit(per_page).to_a,
        page
      ]
    end
    
    def previous_page?(documents, page, per_page)
      page > 1
    end
    
    def next_page?(documents, page, per_page)
      documents.size == per_page
    end
    
    def post_path(post)
      if post.idea?
        "/idea/#{post.slug}"
      else
        "/post/#{post.slug}"
      end
    end
    
    def comment_path(post)
      "/post/#{post.slug}/comments"
    end
    
    def h(text)
      Rack::Utils.escape_html text
    end
    
    def short_datetime(time)
      time.strftime "%Y-%m-%d"
    end
    
    def long_datetime(time)
      time.xmlschema
    end
    
    def short_date(time)
      if Time.now.year == time.year
        time.strftime "%b #{time.day}"
      else
        time.strftime "%b #{time.day}, %Y"
      end
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

    def markdown(text)
      renderer = Redcarpet::Render::HTML.new(
        hard_wrap: true
      )

      markdowned = Redcarpet::Markdown.new(
        renderer,
        # no_intra_emphasis: true, 
        autolink: true, 
        space_after_headers: true
      )

      markdowned.render text
    end

    def post_excerpt(post)
      markdown post.excerpt || ""
    end

    def post_body(post)
      body = markdown render_songs(post.body, post.slug)

      # hack: make standalone img tags stand alone
      body.gsub!(/<p>(<img [^>]+>)<\/p>/) do
        "<div class=\"container\">#{$1}</div>" 
      end

      # even standalone img tags with links around them
      body.gsub!(/<p>(<a [^>]+>?<img [^>]+><\/a>)<\/p>/) do
        "<div class=\"container\">#{$1}</div>" 
      end

      body
    end
    
    def comment_body(body)
      renderer = Redcarpet::Render::HTML.new(
        filter_html: true,
        safe_links_only: true
      )

      markdown = Redcarpet::Markdown.new(
        renderer,
        no_intra_emphasis: true,
        autolink: true, 
        space_after_headers: true
      )

      markdown.render body
    end
    
    def url_escape(url)
      URI.escape url
    end
    
    def render_songs(body, slug)
      body.gsub /(?:<p>\s*)?\[song "([^"]+)"\].*?\[name\](.*?)\[\/name\].*?\[by(?: "([^"]+)")?\](.*?)\[\/by\].*?\[\/song\](?:\s*<\/p>)?/im do
        partial "song", engine: :erb, locals: {
          filename: $1,
          name: $2,
          link: $3,
          by: $4,
          slug: slug
        }
      end
    end
    
  end
end