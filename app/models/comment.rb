 class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :post

  attr_protected :_id, :hidden, :ip, :flagged, :mine

  field :author
  field :author_url
  field :author_email
  field :body
  field :ip
  field :hidden, type: Boolean, default: false
  field :flagged, type: Boolean, default: false
  field :mine, type: Boolean, default: false

  # cache the rendered, sanitized body
  field :body_rendered

  index author: 1
  index author_url: 1
  index author_email: 1
  index hidden: 1
  index ip: 1
  index flagged: 1
  index mine: 1
  index created_at: 1
  index post_id: 1

  # index the way these are asked for
  index({post_id: 1, hidden: 1, flagged: 1, created_at: 1})

  validates_presence_of :body
  validates_presence_of :author
  validates_presence_of :author_email

  scope :visible, where(hidden: false, flagged: false)
  scope :flagged, where(flagged: true)
  scope :ham, where(flagged: false)


  # prefix URLs with http:// if they exist and don't have it
  before_create :adjust_url
  def adjust_url
    if self.author_url.present? and (self.author_url !~ /^https?:\/\//)
      self.author_url = "http://#{author_url}"
    end
  end

  after_save :update_post_count!
  after_destroy :update_post_count!
  def update_post_count!
    self.post.update_count!
  end


  # mixing in the rendering methods...
  include ::Helpers::Rendering

  before_save :render_fields
  def render_fields
    self.body_rendered = render_comment_body self.body
  end



  # spam protection
  include Rakismet::Model

  # not saved to db
  attr_accessor :user_agent, :referrer

  rakismet_attrs author_email: :author_email,
    comment_type: "comment", content: :body,
    permalink: nil, user_ip: :ip
end