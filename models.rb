class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  attr_protected :_id
  
  references_many :comments
  
  field :title
  field :body
  field :published_at, :type => Time
  
  # organization - types and tags
  field :post_type, :type => Array
  field :tags, :type => Array
  
  # flags
  field :private, :type => Boolean, :default => false
  field :draft, :type => Boolean, :default => true
  
  index :published_at
  index :post_type
  index :tags
  index :private
  index :draft
  
  slug :title
  index :slug
  validates_uniqueness_of :slug, :allow_nil => true
  
  index :imported_at
  index :import_source
  index :import_source_filename
  
  
  scope :visible, :where => {:private => false, :draft => false}
end


class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :post
  
  attr_protected :hidden, :ip, :imported_at, :import_source, :import_source_filename
  
  field :author
  field :author_url
  field :body
  field :hidden, :type => Boolean, :default => false
  field :ip
  
  index :author
  index :hidden
  index :ip
  
  index :imported_at
  index :import_source
  index :import_source_filename
  
  
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