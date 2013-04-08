# encoding: utf-8

module Helpers
  module Admin

    def form_escape(string)
      string ? string.gsub("\"", "&quot;") : nil
    end

  end
end