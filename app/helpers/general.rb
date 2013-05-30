# encoding: utf-8

require 'nokogiri'
require 'loofah'

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

    def custom_tags(text)
      text.gsub!(/\[(left|right)\s+(\d{4}-\d{2}-\d{2}\s+)?([^\]]+)\]/i) do
        date = Time.zone.parse($2).strftime("%b %d, %Y") if $2
        "<small class=\"#{$1}\">
          <span>#{$3}</span>" +
          (date ? "<time datetime=\"#{$2}\">#{date}</time>" : "") +
        "</small>"
      end

      # hack: make standalone img tags stand alone
      text.gsub!(/<p>(<img [^>]+>)<\/p>/) do
        "<div class=\"container\">#{$1}</div>"
      end

      # even standalone img tags with links around them
      text.gsub!(/<p>(<a [^>]+>?<img [^>]+><\/a>)<\/p>/) do
        "<div class=\"container\">#{$1}</div>"
      end

      text
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

    def post_excerpt(post, render_options = {})
      text = post.excerpt || ""
      text = markdown text
      text = custom_tags text
      text
    end

    def post_body(text)
      text = markdown text
      text = custom_tags text
      text
    end

    # small excerpt is text only, filter out html
    def small_excerpt(post)
      excerpt(strip_tags(sanitize(post_excerpt post)), (170 - post.title.size))
    end

    def excerpt(text, max)
      if text.size > max
        text[0..max-3] + "…"
      else
        text
      end
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

    def strip_tags(string)
      doc = Nokogiri::HTML string
      (doc/"//*/text()").map do |text|
        text.inner_text.strip
      end.select {|text| text.present?}.join " "
    end

    def sanitize(string)
      return nil unless string
      Loofah.scrub_fragment(string, :prune).to_s.strip
    end

  end
end