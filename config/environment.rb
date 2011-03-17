require 'sinatra'
require 'mongoid'
require 'mongoid/slug'
require 'rakismet'

def config
  @config ||= YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
end

configure do
  Mongoid.configure {|c| c.from_hash config[:mongoid]}
  Rakismet.key = config[:rakismet][:key]
  Rakismet.url = config[:rakismet][:url]
  Rakismet.host = config[:rakismet][:host]
end

require 'models'

# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "config/environment.rb"
  config.also_reload "blog.rb"
  config.also_reload "models.rb"
  config.also_reload "admin.rb"
  config.also_reload "helpers.rb"
end

set :logging, false