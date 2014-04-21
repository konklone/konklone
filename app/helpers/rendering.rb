require 'nokogiri'
require 'loofah'
require 'rinku'

require 'kramdown' # TODO: no
require 'redcarpet'

# Pygments means the running box has a PYTHON 2.X dependency.
require 'pygments.rb'

# needs to be safe enough to be included into a Mongoid model

module Helpers
  module Rendering

    class HTMLwithPygments < Redcarpet::Render::HTML
      def block_code(code, language)
        Pygments.highlight(code,
          lexer: language,
          options: {cssclass: "highlight"}
        )
      end
    end

    # any field-specific render methods begin with "render_"

    def post_body(post)
      if Environment.config['site']['cache_markdown']
        post.body_rendered
      else
        render_post_body post.body
      end
    end

    def post_nav(post)
      if Environment.config['site']['cache_markdown']
        post.nav
      else
        render_post_nav post.body
      end
    end

    def comment_body(comment)
      if Environment.config['site']['cache_markdown']
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
      with_nav = kramdown with_nav

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

    # documentation at:
    # https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
    def markdown(text)
      renderer = HTMLwithPygments.new(
        with_toc_data: true
      )

      markdown = Redcarpet::Markdown.new(renderer, {
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        autolink: true,
        disable_indented_code_blocks: true,
        lax_spacing: true,
        space_after_headers: true,
        with_toc_data: true
      })

      markdown.render text
    end

    def kramdown(text)
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

    def capital_H_dangit(string)
      string.to_s
        .gsub(/(\A|\s)github(\W)/i, '\1GitHub\2') # capitalize GitHub in every occurrence.
        .gsub(/github\.(com|io)/i, 'github.\1')   # reset URL's.
    end

  end
end
