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
  field :flagged, type: Boolean, default: false

  field :versions, type: Array, default: []

  field :comment_count, type: Integer, default: 0
  
  # MARKEDFORDEATH
  field :display_title, type: Boolean, default: true

  # MARKEDFORDEATH
  field :post_type, type: Array, default: ["blog"]
  

  index :slug
  index :published_at
  index :post_type
  index :tags
  index :private
  index :draft
  index :created_at
  index :comment_count
  
  validates_uniqueness_of :slug, allow_nil: true
  
  scope :visible, where: {:private => false, draft: false}
  scope :drafts, where: {draft: true}
  scope :private, where: {:private => true}
  scope :flagged, where: {flagged: true}
  
  scope :admin_search, lambda {|query|
    {where: {"$or" => 
      [:body, :title, :excerpt, :slug].map {|key| {key => regex_for(query)}}
     }}
  }

  scope :channel, lambda {|type| {where: {post_type: type}}}

  def update_count!
    self.comment_count = self.comments.ham.count
    self.save!
  end

  def visible?
    !private and !draft
  end
  
  def self.regex_for(value)
    regex_value = value.dup
    %w{+ ? . * ^ $ ( ) [ ] { } | \ }.each {|char| regex_value.gsub! char, "\\#{char}"}
    /#{regex_value}/i
  end

  # snap current values to the end of the versions array, but don't save
  def snap_version(because)
    version = {
      replaced_at: Time.now,
      replaced_because: because,

      last_updated_at: self.updated_at,
      draft: self.draft,
      private: self.private,

      title: self.title,
      excerpt: self.excerpt,
      body: self.body
    }

    self.versions << version
  end
end