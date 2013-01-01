class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :post
  
  attr_protected :_id, :hidden, :ip, :flagged, :mine
  
  field :author
  field :author_url
  field :body
  field :ip
  field :hidden, type: Boolean, :default => false
  field :flagged, type: Boolean, :default => false
  field :mine, type: Boolean, :default => false
  
  index :author
  index :author_url
  index :hidden
  index :ip
  index :flagged
  index :mine
  index :created_at
  
  validates_presence_of :body
  validates_presence_of :author
  
  scope :visible, where: {hidden: false, flagged: false}
  scope :flagged, where: {flagged: true}
  
  
  # prefix URLs with http:// if they exist and don't have it
  before_create :adjust_url
  def adjust_url
    if self.author_url.present? and (self.author_url !~ /^http:\/\//)
      self.author_url = "http://#{author_url}"
    end
  end
  
  
  # spam protection
  include Rakismet::Model
  
  # not saved to db
  attr_accessor :user_agent, :referrer
  
  rakismet_attrs author_email: nil,
    comment_type: "comment", content: :body,
    permalink: nil, user_ip: :ip
end