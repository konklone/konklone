#!/usr/bin/env ruby

require 'config/environment'

get '/' do
  Post.all(:sort => [:created_at, 1]).map do |post|
    "#{post.title}:\n<br/>#{post.body}"
  end.join "\n\n<br/><br/>"
end

get "/posts.json" do
  Post.all.to_json
end

get "/comments.json" do
  Comment.all.to_json
end