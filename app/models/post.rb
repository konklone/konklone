class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  attr_protected :_id, :slug

  has_many :comments

  field :title
  slug :title, permanent: true

  field :body
  field :excerpt
  field :footer # raw html to include in footer

  # some cached rendered fields
  field :body_rendered
  field :excerpt_rendered
  field :excerpt_text # plain-text

  field :published_at, type: Time
  field :tags, type: Array, default: []

  field :private, type: Boolean, default: false
  field :draft, type: Boolean, default: true
  field :flagged, type: Boolean, default: false

  field :versions, type: Array, default: []

  field :comment_count, type: Integer, default: 0

  # MARKEDFORDEATH
  field :display_title, type: Boolean, default: true

  # MARKEDFORDEATH
  field :post_type, type: Array, default: ["blog"]


  index _slugs: 1
  index published_at: 1
  index post_type: 1
  index tags: 1
  index private: 1
  index draft: 1
  index created_at: 1
  index comment_count: 1

  # index the way posts are found
  index({published_at: 1, private: 1, draft: 1})
  index({_slugs: 1, private: 1, draft: 1})

  validates_uniqueness_of :slug, allow_nil: true

  scope :visible, where(private: false, draft: false)

  scope :drafts, where(draft: true)
  scope :private, where(private: true)
  scope :flagged, where(flagged: true)

  scope :admin_search, lambda {|query|
    where({"$or" =>
      [:tags, :body, :title, :excerpt, :slug].map {|key| {key => regex_for(query)}}
    })
  }

  scope :tagged, lambda {|tag| where(tags: tag)}

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

  # includes normal saves, and comment adding (thanks to the comment counter)
  after_save :uncache!
  def uncache!
    Environment.uncache!(slug) if config[:site]['cache_enabled']
  end

  # mixing in the rendering methods...
  include ::Helpers::Rendering

  before_save :render_fields
  def render_fields
    self.body_rendered = render_post_body self.body
    self.excerpt_rendered = render_post_excerpt self.excerpt
    self.excerpt_text = render_post_excerpt_text self.excerpt
  end
end