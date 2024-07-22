require "test_helper"

class AvatarsTest < ActionDispatch::IntegrationTest
  test "returns 404 when no user is found" do
    get avatar_user_path("user", size: 64)

    assert_response :not_found
  end

  test "redirects to default avatar when gravatar returns 404" do
    stub_request(:get, Addressable::Template.new("https://secure.gravatar.com/avatar/{hash}.png?d=404&r=PG&s={size}"))
      .to_return(status: 404)

    user = create(:user)
    get avatar_user_path(user.id, size: 64)

    assert_response :found
    assert_equal "http://localhost/images/avatar.svg", response.headers["Location"]
  end

  test "serves gravatar response on 200" do
    stub_request(:get, Addressable::Template.new("https://secure.gravatar.com/avatar/{hash}.png?d=404&r=PG&s=64"))
      .to_return(status: 200, body: "image", headers: {
                   "Content-Type" => "image/jpeg",
                   "Last-Modified" => "Wed, 21 Oct 2015 07:28:00 GMT",
                   "Link" => "foo"
                 })

    user = create(:user)
    get avatar_user_path(user.id, size: 64)

    assert_response :success
    assert_equal "image/jpeg", response.headers["Content-Type"]
    assert_equal "image", response.body
    assert_nil response.headers["Link"]
  end

  test "serves default avatar with theme when user has no gravatar" do
    user = create(:user)
    get avatar_user_path(user.id, size: 64, theme: "dark")

    assert_response :found
    assert_equal "http://localhost/images/avatar_inverted.svg", response.headers["Location"]
  end

  test "falls back to default avatar when gravatar returns 500" do
    stub_request(:get, Addressable::Template.new("https://secure.gravatar.com/avatar/{hash}.png?d=404&r=PG&s=64"))
      .to_return(status: 500)

    user = create(:user)
    get avatar_user_path(user.id, size: 64)

    assert_response :found
    assert_equal "http://localhost/images/avatar.svg", response.headers["Location"]
  end

  test "returns 400 when size is invalid" do
    user = create(:user)
    get avatar_user_path(user.id, size: 0)

    assert_response :bad_request
    assert_equal "Invalid size", response.body

    get avatar_user_path(user.id, size: 2049)

    assert_response :bad_request
    assert_equal "Invalid size", response.body
  end

  test "returns 400 when theme is invalid" do
    user = create(:user)
    get avatar_user_path(user.id, size: 64, theme: "unknown")

    assert_response :bad_request
    assert_equal "Invalid theme", response.body
  end
end
