require 'nokogiri'
require 'loofah'
require 'kramdown'
require 'rinku'

# needs to be safe enough to be included into a Mongoid model

module Helpers
  module Rendering

    # any field-specific render methods begin with "render_"

    def post_body(post)
      if config[:site]['cache_markdown']
        post.body_rendered
      else
        render_post_body post.body
      end
    end

    def post_nav(post)
      if config[:site]['cache_markdown']
        post.nav
      else
        render_post_nav post.body
      end
    end

    def comment_body(comment)
      if config[:site]['cache_markdown']
        comment.body_rendered
      else
        render_comment_body comment.body
      end
    end

    def render_post_body(text)
      text = markdown text
      text = custom_tags text
      text
    end

    # extract post nav as isolated html fragment
    def render_post_nav(text)
      with_nav = "* anything\n{:toc}\n\n#{text}"
      with_nav = markdown with_nav
      nav = Nokogiri::HTML(with_nav).css("ul#markdown-toc").first
      nav ? nav.to_html : nil
    end

    def render_post_excerpt(text, render_options = {})
      text = text || ""
      text = markdown text
      text = custom_tags text
      text
    end

    # sanitize comments pre-markdown
    def render_comment_body(text)
      sanitized = strip_tags sanitize(text)
      sanitized = Rinku.auto_link sanitized, :all, "rel='nofollow'"
      markdown sanitized
    end

    # sanitize text-only excerpt post-markdown
    def render_post_excerpt_text(text)
      strip_tags sanitize(render_post_excerpt(text))
    end


    # tags, markdown, sanitization

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
      Kramdown::Document.new(text).to_html
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