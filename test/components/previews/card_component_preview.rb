class CardComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param title text "Card title"
  # @param icon text "icon name"
  # @param count number "count (blank for no count)"
  # @param url url "view all link (blank for no link)"
  def default(title: "Gems", icon: "gems", count: nil, url: nil)
    render CardComponent.new do |c|
      c.head(title, icon: icon, count: count, url: url)
      c.list do
        c.list_item { "list > list_item" }
      end
    end
  end

  def divided_list(title: "Gems", icon: "gems", count: nil, url: nil)
    render CardComponent.new do |c|
      c.head(title, icon: icon, count: count)
      c.divided_list do
        c.list_item { "divided_list > list_item" }
        c.list_item_to("#") { "divided_list > list_item_to" }
        c.list_item { "divided_list > list_item" }
      end
      c.list_item_to(url) { "View all" } if url
    end
  end

  def scrollable(title: "History")
    render CardComponent.new do |c|
      c.head do
        c.title(title, icon: :history)
      end
      c.scrollable do
        render Card::TimelineComponent.new do |t|
          t.timeline_item(Time.current) { "timeline_item > content" }
        end
        render Card::TimelineComponent.new do |t|
          t.timeline_item(1.day.ago) { "timeline_item > content" }
        end
        render Card::TimelineComponent.new do |t|
          t.timeline_item(2.days.ago) { "timeline_item > content" }
        end
        render Card::TimelineComponent.new do |t|
          t.timeline_item(1.week.ago) { "timeline_item > content" }
        end
        render Card::TimelineComponent.new do |t|
          t.timeline_item(1.month.ago) { "timeline_item > content" }
        end
        render Card::TimelineComponent.new do |t|
          t.timeline_item(1.year.ago) { "timeline_item > content" }
        end
      end
    end
  end
end
