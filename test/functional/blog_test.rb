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

  def test_visiting_a_draft_post
    post = create :post, draft: true, private: false
    get "/post/#{post.slug}"
    assert_response 404
  end

  def test_visiting_a_private_post
    post = create :post, draft: false, private: true
    get "/post/#{post.slug}"
    assert_response 404
  end

  def test_visiting_admin
    get "/admin"
    assert_response 200
  end

  def test_visiting_admin_post
    post = create :published_post
    get "/admin/post/#{post.slug}"
    assert_response 404
  end

  # TODO: ensure admin area is accessible to admin

end