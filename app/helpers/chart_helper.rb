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
    chart = GoogleChart::LineChart.new('630x400', "Downloads over the last #{pluralize(days_ago, 'day')}") do |lc|
      versions = downloads_over_time(versions, days_ago)
      versions.each_with_index do |v, idx|
        lc.data v[:slug], v[:counts], v[:color]
      end

      max = versions.map{|v| v[:counts].max}.max
      range = [0, max]

      lc.axis :y, :range => range
      lc.axis :x, :labels => downloads_over_time_labels
      lc.grid :x_step         => 100.0 / 12.0,
              :y_step         => 100.0 / 15.0,
              :length_segment => 1,
              :length_blank   => 5
    end
    image_tag(chart.to_url(:chf => 'bg,s,FFFFFF00'), :alt => 'title')
  end
  
  def downloads_over_time_labels
    [60, 40, 20, 0].map { |t| t.days.ago.to_date }
  end

  def downloads_over_time(versions, days_ago = 90)
    download_counts = Download.counts_by_day_for_versions(versions, days_ago)
    versions.map.with_index do |version, idx|
      counts = []
      days_ago.times do |t|
        date     = t.days.ago.to_date
        count    = download_counts["#{version.id}-#{date}"] || 0
        counts << count
      end
      {
        :slug => version.slug, 
        :counts => counts.reverse, 
        :color => color_from_cycle(idx, versions.size) 
      }
    end
  end

  def downloads_over_time_chart_dates(days_ago = 90)
    (0..days_ago).map { |n| n.days.ago.to_date }.reverse.map { |date| date.strftime("%m/%d") }
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
