#!/usr/bin/env ruby

require 'config/environment'

get '/' do
  erb :index, :locals => {:posts => Post.visible.desc(:published_at).limit(10)}
end