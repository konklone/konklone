class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type

  index type: 1

  def self.bad_comment!(comment)
    create! type: "bad_comment", comment: comment.attributes
  end
end