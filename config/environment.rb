require 'sinatra'

require 'mongoid'
require 'mongoid/slug'

require 'rakismet'

require 'redcarpet'

require 'sinatra/content_for'
require 'sinatra/flash'
require 'tzinfo'

set :logging, false
set :views, 'app/views'
set :public_folder, 'public'
set :sessions, true


def config
  @config ||= YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
end

configure do
  Mongoid.configure {|c| c.from_hash config[:mongoid]}

  Rakismet.key = config[:rakismet][:key]
  Rakismet.url = config[:rakismet][:url]
  Rakismet.host = config[:rakismet][:host]

  Time.zone = ActiveSupport::TimeZone.find_tzinfo "America/New_York"
end


Dir.glob('app/models/*.rb').each {|filename| load filename}


# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "./config/environment.rb"
  config.also_reload "./konklone.rb"
  config.also_reload "./app/models/*.rb"
  config.also_reload "./app/controllers/*.rb"
  config.also_reload "./app/helpers/*.rb"
end


# extra controllers and helpers

Dir.glob("./app/controllers/*.rb").each {|filename| load filename}

Dir.glob('app/helpers/*.rb').each {|filename| load filename}
helpers Helpers::General
helpers Helpers::Admin

require 'padrino-helpers'
helpers Padrino::Helpers