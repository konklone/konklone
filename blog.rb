#!/usr/bin/env ruby

require 'config/environment'
require 'helpers'

set :views, 'views'
set :public, 'public'

get '/' do
  erb :index, :locals => {:posts => Post.visible.desc(:published_at).limit(10)}
end