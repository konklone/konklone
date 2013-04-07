module Helpers
  module Admin

    def form_escape(string)
      string ? string.gsub("\"", "&quot;") : nil
    end

    def excerpt(text, max)
      if text.size > max
        text[0..max-3] + "…"
      else
        text
      end
    end

  end
end