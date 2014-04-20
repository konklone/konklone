task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require './config/environment'
end

# load 'importers/blog0/blog0.rake'
# load 'importers/blog1/blog1.rake'
# load 'importers/blog2/blog2.rake'
# load 'importers/blog3/blog3.rake'

# Dir.glob("syncers/*.rake").each {|f| load f}

desc "Create indexes on posts and comments"
task :create_indexes => :define_import_indexes do
  begin
    Mongoid.models.each &:create_indexes
    puts "Created indexes for posts and comments."
  rescue Exception => ex
    Email.exception ex
    puts "Error creating indexes, emailed report."
  end
end

# indexes on fields used only in importing
task :define_import_indexes => :environment do
  class Post
    index imported_at: 1
    index import_source: 1
    index import_source_filename: 1
    index import_song_filename: 1
    index import_id: 1
    index import_sequence: 1 # LJ post sequence IDs
  end

  class Comment
    index imported_at: 1
    index import_source: 1
    index import_source_filename: 1
    index import_id: 1
    index import_post_id: 1
  end
end

desc "Set the crontab in place for this environment"
task set_crontab: :environment do
  environment = ENV['environment']
  current_path = ENV['current_path']

  if environment.blank? or current_path.blank?
    puts "No environment or current path given, exiting."
    exit
  end

  if system("cat #{current_path}/config/cron/#{environment}.crontab | crontab")
    puts "Successfully overwrote crontab."
  else
    Email.message "Crontab overwriting failed on deploy."
    puts "Unsuccessful in overwriting crontab, emailed report."
  end
end

desc "Generate a sitemap."
task :sitemap => :environment do
  require 'big_sitemap'

  include Helpers::General

  ping = ENV['debug'] ? false : true

  count = 1 # assume / works

  BigSitemap.generate(
    base_url: "https://konklone.com",
    document_root: "public/sitemap",
    url_path: "sitemap",
    ping_google: ping,
    ping_bing: ping) do

    add "/", change_frequency: "daily"

    Post.visible.desc(:published_at).each do |post|
      add post_path(post), change_frequency: "weekly"
      count += 1
    end
  end

  puts "Saved sitemap with #{count} links."
end


namespace :cache do
  desc "Reset post cache"
  task reset: :environment do
    if config[:site]['cache_enabled']
      system "rm #{Environment.cache_dir}/*"

      # proactive caching.

      # all right this is crazy, but to avoid simulating Sinatra's
      # whole render pipeline and helper set up.
      # we will hit the app locally and trigger the render step for each post, at deploy time
      Post.visible.desc(:published_at).each do |post|
        puts "[#{post.slug}] Caching..."
        system "curl --silent #{config[:site]['local_root']}/post/#{post.slug} > /dev/null"
      end

      puts
      puts "Reset the cache. I hope you're happy."
    else
      puts "Cache not enabled, not resetting anything."
    end
  end
end

namespace :analytics do

  task google: :environment do
    begin
      day = ENV['day'] || 1.day.ago.strftime("%Y-%m-%d")

      start_time = Time.zone.parse(day).midnight
      end_time = start_time + 1.day

      msg = google_report start_time, end_time
      # Email.message "Google activity for #{day}", msg
      puts msg
    rescue Exception => ex
      # Email.exception 'analytics:google', "Exception preparing analytics:google", ex
      puts "Error sending analytics, emailed report."
    end
  end

  def google_report(start_time, end_time)
    hits = Event.where(type: "google", last_google_hit: {
      "$gte" => start_time, "$lt" => end_time
    })
    types = hits.distinct(:url_type).sort_by &:to_s

    slow = 200
    slow_hits = hits.where(my_ms: {"$gt" => slow}).asc(:my_ms)

    url_types = {}
    types.each do |type|
      criteria = hits.where(url_type: type)

      url_types[type] = {}
      url_types[type][:count] = criteria.count
      url_types[type][:avg] = (criteria.only(&:my_ms).map(&:my_ms).sum.to_f / url_types[type][:count]).round
    end

    total_count = hits.count
    if total_count > 0
      total_avg = (hits.only(&:my_ms).map(&:my_ms).sum.to_f / total_count).round
    else
      total_avg = 0
    end


    msg = "Crawling activity (avg measured by konklone, external est adds 10ms)\n\n"
    offset = 10

    max_type = types.map {|t| t.to_s.size}.max
    max_count = url_types.values.map {|t| t[:count].to_s.size}.max
    max_avg = url_types.values.map {|t| t[:avg].to_s.size}.max

    types.each do |type|
      count = fix url_types[type][:count], max_count
      avg = fix url_types[type][:avg], max_avg
      est = fix "~#{url_types[type][:avg] + offset}", (max_avg + 1)
      fixed_type = fix type, max_type, :right
      msg << "  /#{fixed_type} - #{count} hits (avg #{avg}ms, est #{est}ms)\n"
    end

    msg << "\n  total: #{total_count} (avg: #{total_avg}ms, est #{total_avg + offset}ms)\n"

    msg << "\n\nSlow hits (>#{slow}ms as measured in Scout)\n\n"

    max_slow = slow_hits.only(&:my_ms).map {|h| h.my_ms.to_s.size}.max

    slow_hits.each do |hit|
      ms = fix hit.my_ms, max_slow
      msg << "  #{ms}ms - #{URI.decode hit.url}\n"
    end

    msg
  end

  def fix(obj, width, side = :left)
    obj = obj.to_s
    spaces = width - obj.size
    spaces = 0 if spaces < 0
    space = " " * spaces

    if side == :left
      space + obj
    else
      obj + space
    end
  end
end
