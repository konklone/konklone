require 'sinatra'
require 'safe_yaml'

require 'mongoid'
require 'mongoid_slug'

require 'sinatra/partial'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'tzinfo'
require 'escape_utils'

set :logging, false
set :views, 'app/views'
set :public_folder, 'public'
set :partial_template_engine, :erb # required by sinatra-partial

class Environment

  def self.config
    @config ||= YAML.safe_load_file File.join(File.dirname(__FILE__), "config.yml")
  end

  # my own slugifier
  def self.to_url(string)
    string = string.dup
    string.gsub! /[^\w\-\s]+/, ""
    string.gsub! /\s+/, '-'
    string.downcase!
    string[0..200]
  end

end

configure do
  SafeYAML::OPTIONS[:default_mode] = :safe

  Mongoid.configure do |c|
    c.load_configuration Environment.config['mongoid'][Sinatra::Base.environment.to_s]
  end

  Time.zone = ActiveSupport::TimeZone.find_tzinfo "America/New_York"
end


# disable sessions in test environment so it can be manually set
unless test?
  use Rack::Session::Cookie,
    key: 'rack.session',
    path: '/',
    expire_after: (60 * 60 * 24 * 30),
    secret: Environment.config['site']['session_secret']
end


# helpers first, models depend on them
Dir.glob('app/helpers/*.rb').each {|filename| load filename}
helpers Helpers::General
helpers Helpers::Rendering
helpers Helpers::Admin

Dir.glob("./app/models/*.rb").each {|filename| load filename}
Dir.glob("./app/controllers/*.rb").each {|filename| load filename}
