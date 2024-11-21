class Card::TimelineComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param datetime datetime-local "datetime"
  # @param user_link url "user link"
  # @param content text "content"
  def default(datetime: 1.day.ago, user_link: nil, content: nil)
    block = proc { content } if content

    render CardComponent.new do |c|
      c.head("Timeline", icon: "history")
      c.scrollable do
        render Card::TimelineComponent.new do |t|
          t.timeline_item(datetime, user_link, &block)
        end
      end
    end
  end

  def with_content(datetime: 1.day.ago, user_link: nil)
    render CardComponent.new do |c|
      c.head("Timeline", icon: "history")
      c.scrollable do
        render Card::TimelineComponent.new do |t|
          t.timeline_item(datetime, user_link) do
            <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
              <div class="flex text-b1 text-neutral-800 dark:text-white"><a href="#">gemname</a></div>
              <code class="px-2 text-c3 bg-green-200 dark:bg-green-800 rounded-sm text-neutral-900 dark:text-white">1.63.1</code>
            HTML
          end
        end
      end
    end
  end
end
