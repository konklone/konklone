require 'sinatra'

require 'mongoid'
require 'mongoid_slug'

require 'rakismet'

require 'escape_utils'
require 'redcarpet'

require 'sinatra/content_for'
require 'sinatra/flash'
require 'tzinfo'

require 'pony'
require './config/email'

set :logging, false
set :views, 'app/views'
set :public_folder, 'public'


def config
  @config ||= YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
end

configure do
  Mongoid.configure do |c|
    c.load_configuration config['mongoid'][Sinatra::Base.environment.to_s]
  end

  Rakismet.key = config[:rakismet][:key]
  Rakismet.url = config[:rakismet][:url]
  Rakismet.host = config[:rakismet][:host]

  Time.zone = ActiveSupport::TimeZone.find_tzinfo "America/New_York"
end


# disable sessions in test environment so it can be manually set
unless test?
  use Rack::Session::Cookie,
    key: 'rack.session',
    path: '/',
    expire_after: (60 * 60 * 24 * 30),
    secret: config[:site]['session_secret']
end


Dir.glob('app/models/*.rb').each {|filename| load filename}


# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "./config/*.rb"
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