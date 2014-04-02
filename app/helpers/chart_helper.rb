module ChartHelper
  def most_downloaded_chart(rubygems)
    chart = GoogleChart::BarChart.new('530x360', "Most Downloads", :horizontal, false) do |bc|
      downloads = rubygems.map(&:downloads)

      bc.axis :y, :labels    => rubygems.map(&:with_downloads).reverse,
                  :font_size => 16,
                  :alignment => :center
      bc.axis :x, :range     => [0, downloads.max],
                  :font_size => 16,
                  :alignment => :center
      bc.data "downloads", downloads, '8B0000'
      bc.show_legend = false
    end
    image_tag chart.to_url
  end
end
