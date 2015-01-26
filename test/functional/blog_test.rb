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

  def test_visiting_admin_with_slash
    get "/admin/"
    assert_response 200
  end

  def test_visiting_admin_post
    post = create :published_post
    get "/admin/post/#{post.slug}"
    assert_response 404
  end

  def test_visiting_preview_published
    post = create :published_post
    get "/admin/preview/#{post.id}"
    assert_response 200
  end

  def test_visiting_preview_draft
    post = create :draft_post
    get "/admin/preview/#{post.id}"
    assert_response 200
  end

  def test_visiting_preview_draft_but_private
    post = create :draft_post
    post.private = true
    post.save!
    get "/admin/preview/#{post.id}"
    assert_response 404
  end

  # TODO: ensure admin area is accessible to admin

  def test_comment_sanitization

    full_tests = {
      "hey `there`" => "<p>hey <code>there</code></p>",

      "hey `<b>`" => "<p>hey <code>&lt;b&gt;</code></p>",

      # this one is not desired, but it's safe and acceptable
      "hey `<script>`" => "<p>hey <code>&lt;script&gt;</code></p>",

      "hey `<link href=\"what\">`" => "<p>hey <code>&lt;link href=\"what\"&gt;</code></p>",

      "hey <script>" => "<p>hey &lt;script&gt;&lt;/script&gt;</p>",
      "hey <script>yes</script>" => "<p>hey &lt;script&gt;yes&lt;/script&gt;</p>",
      "hey <b>yes</b>" => "<p>hey <b>yes</b></p>",
    }

    full_tests.each do |input, output|
      assert_equal output, routing.render_comment_body(input).strip
    end


  end

end