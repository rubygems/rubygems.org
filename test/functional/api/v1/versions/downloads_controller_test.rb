require "test_helper"

class Api::V1::Versions::DownloadsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @rubygem = create(:rubygem, number: "0.1.0")
      get :index, params: { version_id: @rubygem.latest_version.number, format: "json" }
    end

    should respond_with :gone
  end

  context "on GET to search" do
    setup do
      @rubygem = create(:rubygem, number: "0.1.0")
      get :search, params: { version_id: @rubygem.latest_version.number, format: "json" }
    end

    should respond_with :gone
  end
end
