require "test_helper"

class Card::TimelineComponentTest < ComponentTest
  should "render timeline item without link to user" do
    datetime = 1.2.days.ago

    render Card::TimelineComponent.new do |c|
      c.timeline_item(datetime) do
        "additional content"
      end
    end

    assert_selector "time[datetime='#{datetime.iso8601}']"
    assert_text "additional content"
  end
end
