class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  attr_protected :_id, :slug
  
  references_many :comments
  
  field :title
  slug :title, permanent: true
  
  field :body
  field :published_at, type: Time
  field :tags, type: Array, default: []

  field :excerpt

  field :private, type: Boolean, default: false
  field :draft, type: Boolean, default: true
  field :display_title, type: Boolean, default: true

  # channel the post appears in
  field :post_type, type: Array, default: ["blog"]
  
  index :slug
  index :published_at
  index :post_type
  index :tags
  index :private
  index :draft
  index :created_at
  
  validates_uniqueness_of :slug, allow_nil: true
  
  scope :visible, where: {:private => false, draft: false}
  
  scope :search, lambda {|query|
    {where: {"$or" => 
      [:body, :title, :excerpt, :slug].map {|key| {key => regex_for(query)}}
     }}
  }

  scope :channel, lambda {|type| {where: {post_type: type}}}
  
  def visible?
    !private and !draft
  end

  def idea?
    post_type.include? "idea"
  end
  
  def self.regex_for(value)
    regex_value = value.dup
    %w{+ ? . * ^ $ ( ) [ ] { } | \ }.each {|char| regex_value.gsub! char, "\\#{char}"}
    /#{regex_value}/i
  end
end