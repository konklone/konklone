class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  attr_protected :_id, :slug
  
  references_many :comments
  
  field :title
  slug :title, :permanent => true
  field :body
  field :published_at, :type => Time
  field :post_type, :type => Array, :default => ["blog"]
  field :tags, :type => Array, :default => []
  field :private, :type => Boolean, :default => false
  field :draft, :type => Boolean, :default => true
  field :display_title, :type => Boolean, :default => true
  
  index :slug
  index :published_at
  index :post_type
  index :tags
  index :private
  index :draft
  
  validates_uniqueness_of :slug, :allow_nil => true
  
  scope :visible, :where => {:private => false, :draft => false}
  
  def visible?
    !private and !draft
  end
end


class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :post
  
  attr_protected :hidden, :ip, :flagged, :mine
  
  field :author
  field :author_url
  field :body
  field :ip
  field :hidden, :type => Boolean, :default => false
  field :flagged, :type => Boolean, :default => false
  field :mine, :type => Boolean, :default => false
  
  index :author
  index :author_url
  index :hidden
  index :ip
  index :flagged
  index :mine
  
  validates_presence_of :body
  validates_presence_of :author
  
  scope :visible, :where => {:hidden => false, :flagged => false}
  
  
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
  
  rakismet_attrs :author_email => nil,
      :comment_type => "comment", :content => :body,
      :permalink => nil, :user_ip => :ip
end