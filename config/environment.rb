require 'sinatra'
require 'mongoid'
require 'mongoid/slug'
require 'rakismet'
require 'redcarpet'

def config
  @config ||= YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
end

configure do
  Mongoid.configure {|c| c.from_hash config[:mongoid]}
  Rakismet.key = config[:rakismet][:key]
  Rakismet.url = config[:rakismet][:url]
  Rakismet.host = config[:rakismet][:host]
end

Dir.glob('app/models/*.rb').each {|filename| load filename}

set :logging, false