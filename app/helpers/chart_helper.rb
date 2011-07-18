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

  def downloads_over_time_chart(versions, days_ago = 90)
    download_counts = Download.counts_by_day_for_versions(versions, days_ago)
    range = [nil, 0]
    chart = GoogleChart::LineChart.new('630x400', "Downloads over the last #{pluralize(days_ago, 'day')}") do |lc|
      versions.each_with_index do |version, idx|
        counts = []
        days_ago.times do |t|
          date     = t.days.ago.to_date
          count    = download_counts["#{version.id}-#{date}"] || 0
          range[0] = count if !range[0] || (count < range[0])
          range[1] = count if count > range[1]
          counts << count
        end

        lc.data version.slug, counts.reverse, color_from_cycle(idx, versions.size)
      end

      lc.axis :y, :range => range
      lc.axis :x, :labels => [60, 40, 20, 0].map { |t| t.days.ago.to_date }
      lc.grid :x_step         => 100.0 / 12.0,
              :y_step         => 100.0 / 15.0,
              :length_segment => 1,
              :length_blank   => 5
    end
    image_tag(chart.to_url(:chf => 'bg,s,FFFFFF00'), :alt => 'title')
  end

  def color_from_cycle(idx, length)
    hex    = "0123456789ABCDEF"
    center = 128
    width  = 55 #127
    freq   = Math::PI * 2 / length
    phase  = {:r => 0, :g => 1, :b => 3}

    [ Math.sin(freq*idx+phase[:r]) * width + center,
      Math.sin(freq*idx+phase[:g]) * width + center,
      Math.sin(freq*idx+phase[:b]) * width + center
    ].map { |c| hex.at((c.to_i >> 4) & 0x0F) + hex.at(c.to_i & 0x0F) } * ''
  end
end
