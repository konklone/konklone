require 'sinatra'

require 'mongoid'
require 'mongoid_slug'

require 'rakismet'

require 'sinatra/partial'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'tzinfo'
require 'escape_utils'

require 'octokit'
require 'oj'

require 'pony'
require './config/email'

require "fileutils"

set :logging, false
set :views, 'app/views'
set :public_folder, 'public'
set :partial_template_engine, :erb # required by sinatra-partial

def config
  @config ||= YAML.load_file File.join(File.dirname(__FILE__), "config.yml")
end

class Environment

  def self.github
    if config['github'] and config['github']['token']
      @github ||= Octokit::Client.new access_token: config['github']['token']
    end
  end

  # my own slugifier
  def self.to_url(string)
    string = string.dup
    string.gsub! /[^\w\-\s]+/, ""
    string.gsub! /\s+/, '-'
    string.downcase!
    string[0..200]
  end

  def self.blackouts
    if @blackouts
      @blackouts
    else
      @blackouts = {}
      path = File.join File.dirname(__FILE__), "..", "app", "views", "blackout", "*.html"

      @blackouts = Dir.glob(path).sort.map do |file|
        file = File.basename file, ".html"
        id = file[0..3].to_i
        title = file.sub /^\d+ - /, ''
        {
          title: title,
          id: id,
          slug: "#{id}-#{to_url title}",
          file: file
        }
      end

      @blackouts
    end
  end

  blackouts # pre-calculate
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