require 'RedCloth'
require 'active_record'

# hardcoding useless (to other people) local credentials
ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :host => "localhost",
  :username => "root",
  :database => "ericmill"
)

class OldPost < ActiveRecord::Base
  set_table_name "posts"
  
  has_and_belongs_to_many :categories, :class_name => "OldCategory", :foreign_key => "post_id", :association_foreign_key => "category_id", :join_table => "posts_categories"
  
  has_many :comments, :class_name => "OldComment", :foreign_key => "post_id"
end

class OldComment < ActiveRecord::Base
  set_table_name "comments"
  
  belongs_to :post, :class_name => "OldPost", :foreign_key => "post_id"
end

class OldCategory < ActiveRecord::Base
  set_table_name "categories"
  
  has_and_belongs_to_many :posts, :class_name => "OldPost", :association_foreign_key => "post_id", :foreign_key => "category_id", :join_table => "posts_categories"
end