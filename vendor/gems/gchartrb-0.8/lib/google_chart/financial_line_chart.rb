require File.dirname(__FILE__) + '/base'
module GoogleChart

  # Generates a Financial Line Chart. This feature is UNDOCUMENTED and EXPERIMENTAL.
  # For a sample usage, visit (right at the bottom) http://24ways.org/2007/tracking-christmas-cheer-with-google-charts
  #
  # ==== Examples
  #    flc = GoogleChart::FinancialLineChart.new do |chart|
  #       chart.data "", [3,10,20,37,40,25,68,75,89,99], "ff0000"
  #    end
  #    puts flc.to_url
  #
  class FinancialLineChart < Base
    
    # Specify the 
    # * +chart_size+ in WIDTHxHEIGHT format
    # * +chart_title+ as a string
    def initialize(chart_size='100x15', chart_title=nil) # :yield: self
      super(chart_size, chart_title)
      self.chart_type = :lfi
      self.show_legend = false
      yield self if block_given?
    end

    def process_data
      join_encoded_data(@data.collect { |series|
            encode_data(series, max_data_value)
          })
    end
  end
end
