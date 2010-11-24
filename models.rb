class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  references_many :comments
  
  field :source
  field :title
  field :body
  field :post_type, :type => Array
  field :tags, :type => Array
  field :private, :type => Boolean
  field :draft, :type => Boolean
  field :imported_at, :type => DateTime
  
  slug :title
  
  index :slug
  index :post_type
  index :tags
  index :source
  index :private
  index :draft
  
  validates_uniqueness_of :slug, :allow_nil => true
end


class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :art
  
  field :author
  field :url
  field :body
  field :imported_at, :type => DateTime
  field :source
  field :hidden, :type => Boolean
  field :ip
  
  index :author
  index :source
  index :hidden
  index :ip
  
  validates_presence_of :author
  validates_presence_of :body
  
  # until I figure out foreign keys properly
  def post
    Post.first :conditions => {:slug => article_slug}
  end
end