class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type

  index type: 1

  # for Google activity
  index({type: 1, url: 1})
  index({type: 1, url_type: 1})
  index({type: 1, my_ms: 1})
  index({type: 1, url_type: 1, data: 1})
  index({type: 1, url_type: 1, my_ms: 1})

  def self.bad_comment!(comment)
    create! type: "bad_comment", comment: comment.attributes
  end

  # use direct upsert command for efficiency
  def self.google!(env, start_time)
    url = env['REQUEST_URI'] || env['PATH_INFO']
    pieces = url.split("/")

    now = Time.now

    collection = Mongoid.session(:default)[:events]
    collection.find({type: "google", url: url}).
      upsert({
        "$inc" => {google_hits: 1},
        "$set" => {
          last_google_hit: now,
          url_type: pieces[1],
          url_subtype: pieces[2],
          my_ms: ((now - start_time) * 1000).to_i
        }
      })
  end
end