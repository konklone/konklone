# encoding: utf-8

module Helpers
  module Admin

    def admin?
      session[:admin] == true
    end

    def half_admin?
      session[:half_admin] == true
    end

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

    def tiny_date(time)
      if time.year == Time.now.year
        time.strftime "%m/%d"
      else
        time.strftime "%m/%d/%y"
      end
    end
  end
end