require 'nokogiri'
require 'loofah'

# needs to be safe enough to be included into a Mongoid model

module Helpers
  module Rendering

    # any field-specific render methods begin with "render_"

    def render_post_body(text)
      text = markdown text
      text = custom_tags text
      text
    end

    def render_post_excerpt(text, render_options = {})
      text = text || ""
      text = markdown text
      text = custom_tags text
      text
    end

    # small excerpt is text only, filter out html
    def render_post_excerpt_text(text)
      strip_tags sanitize(render_post_excerpt(text))
    end

    def render_comment_body(text)
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

      markdown.render text
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