# encoding: utf-8

module Helpers
  module Admin

    def form_escape(string)
      string ? string.gsub("\"", "&quot;") : nil
    end

    def link_to_current(text, path)
      if request.path == path
        "<a class=\"active\">#{text}</a>"
      else
        "<a href=\"#{path}\">#{text}</a>"
      end
    end
  end
end