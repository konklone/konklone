module Helpers
  module General

    def header_link(text, paths)
      paths = [paths] unless paths.is_a? Array
      active = paths.select do |path|
        if path.is_a?(String)
          request.path == path
        else
          request.path =~ path
        end
      end.any?

      "<a href=\"#{paths.first}\" class=\"#{active ? "active" : ""}\">#{text}</a>"
    end

    def get_ip
      forwarded = request.env['HTTP_X_FORWARDED_FOR']
      forwarded.present? ? forwarded.split(',').first : nil
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
      "/post/#{post.slug}"
    end

    def comment_path(post)
      "/comments/post/#{post.slug}"
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

    # general rendering - only used for on-display things
    def excerpt(text, max)
      if text.size > max
        text[0..max-3] + "…"
      else
        text
      end
    end

    def small_post_excerpt(post)
      excerpt(post.excerpt_text || "", (170 - post.title.size))
    end
  end
end