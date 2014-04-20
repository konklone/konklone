require './test/test_helper'

class BlogTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include TestHelper::Methods
  include FactoryGirl::Syntax::Methods

  def test_visiting_index
    get "/"
    assert_response 200
  end

  def test_visiting_a_post
    post = create :published_post
    get "/post/#{post.slug}"
    assert_response 200
  end

end