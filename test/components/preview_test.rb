require "test_helper"

class PreviewTest < ComponentTest
  test "all previews render" do
    capture_io { Rails.application.load_seed }

    aggregate_assertions do
      Lookbook::Engine.previews.each do |preview|
        preview.scenarios.each do |scenario|
          refute_nil preview(preview.lookup_path, scenario: scenario.name)
        rescue StandardError => e
          AggregateAssertions::AssertionAggregator.add_error(Minitest::UnexpectedError.new(e))
        end
      end
    end
  end
end
