module ChartHelper
  def most_downloaded_chart(rubygems)
    rubygems.inject([]) do |collection, gem|
      collection.push({name: gem.name, count: gem.downloads});
      collection
    end.to_json.html_safe
  end
end
