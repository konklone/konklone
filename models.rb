class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  attr_protected :_id, :slug
  
  references_many :comments
  
  field :title
  slug :title
  field :body
  field :published_at, :type => Time
  field :post_type, :type => Array
  field :tags, :type => Array
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
end


class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :post
  
  attr_protected :hidden, :ip
  
  field :author
  field :author_url
  field :body
  field :hidden, :type => Boolean, :default => false
  field :mine, :type => Boolean, :default => false
  field :ip
  
  index :author
  index :hidden
  index :ip
  index :mine
  
  validates_presence_of :body
  validates_presence_of :author
  
  scope :visible, :where => {:hidden => false}
  
  before_create :adjust_url
  
  def adjust_url
    if self.author_url !~ /^http:\/\//
      self.author_url = "http://#{author_url}"
    end
  end
end