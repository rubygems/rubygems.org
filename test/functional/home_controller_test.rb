require "test_helper"

class HomeControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      create(:gem_download, count: 11_000_000)
      get :index
    end

    should respond_with :success

    should "display counts" do
      assert page.has_content?("11,000,000")
    end
  end

  should "on GET to index with non html accept header" do
    @request.env["HTTP_ACCEPT"] = "image/gif, image/x-bitmap, image/jpeg, image/pjpeg"

    assert_raises(ActionController::UnknownFormat) do
      get :index
    end
  end

  should "use default locale on GET using invalid one" do
    get :index, params: { locale: "foobar" }
    assert_equal I18n.default_locale, I18n.locale
  end
end
