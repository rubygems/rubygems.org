require "test_helper"

class PreviewTest < ComponentTest
  test "all previews render" do
    Lookbook::Engine.previews.each do |preview|
      preview.scenarios.each do |scenario|
        assert_nothing_raised do
          preview(preview.lookup_path, scenario: scenario.name)
        end
      end
    end
  end
end
