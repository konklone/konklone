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

require "fileutils"

set :logging, false
set :views, 'app/views'
set :public_folder, 'public'


def config
  @config ||= YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
end

class Environment
  def self.cache_dir
    @cache_dir ||= File.join(File.dirname(__FILE__), "..", "cache", "post")
  end

  def self.cache_dest(slug)
    File.join cache_dir, slug
  end

  def self.cache!(slug, content)
    File.open(cache_dest(slug), "w") {|f| f.write content}
  end

  def self.uncache!(slug)
    FileUtils.rm cache_dest(slug)
  rescue Errno::ENOENT
  end
end

configure do
  Mongoid.configure do |c|
    c.load_configuration config['mongoid'][Sinatra::Base.environment.to_s]
  end

  # Mongoid.logger.level = Logger::DEBUG
  # Moped.logger.level = Logger::DEBUG

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

# helpers first, models depend on them
Dir.glob('app/helpers/*.rb').each {|filename| load filename}
helpers Helpers::General
helpers Helpers::Rendering
helpers Helpers::Admin

Dir.glob('app/models/*.rb').each {|filename| load filename}

Dir.glob("./app/controllers/*.rb").each {|filename| load filename}

require 'padrino-helpers'
helpers Padrino::Helpers