module ChartHelper
  def most_downloaded_chart(rubygems)
    chart = GoogleChart::BarChart.new('680x360', "Most Downloads", :horizontal, false) do |bc|
      downloads = rubygems.map(&:downloads)

      bc.axis :y, :labels    => rubygems.map { |rubygem| "#{rubygem.name} (#{rubygem.downloads})" }.reverse,
                  :font_size => 16,
                  :alignment => :center
      bc.axis :x, :range     => [0,downloads.max],
                  :font_size => 16, 
                  :alignment => :center
      bc.data "downloads", downloads, '8B0000'
      bc.show_legend = false
    end
    image_tag chart.to_url
  end
end
