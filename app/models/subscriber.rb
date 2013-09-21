class Subscriber
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email
  field :confirm_code
  field :confirmed_at, type: Time
  field :unsubscribed_at, type: Time

  validates_presence_of :email
  validates_presence_of :confirm_code

  index email: 1
  index confirm_code: 1
  index confirmed_at: 1
  index unsubscribed_at: 1

  # TODO: broadcast method
    # only confirmed users
    # uses postmark

end