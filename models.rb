class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  references_many :comments
  
  field :title
  field :body
  field :published_at, :type => DateTime
  
  # organization - types and tags
  field :post_type, :type => Array
  field :tags, :type => Array
  
  # flags
  field :private, :type => Boolean
  field :draft, :type => Boolean
  
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
  
  field :author
  field :author_url
  field :body
  field :hidden, :type => Boolean
  field :ip
  
  index :author
  index :hidden
  index :ip
  
  validates_presence_of :body
  
  index :imported_at
  index :import_source
  index :import_source_filename
end