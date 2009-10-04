require File.dirname(__FILE__) + '/base'
module GoogleChart
  
  # Generates a Line chart. An option can be passed that allows you to create a Line XY Chart
  #
  # ==== Examples
  #
  #     # Line Chart
  #     lc = GoogleChart::LineChart.new('320x200', "Line Chart", false)
  #     lc.data "Trend 1", [5,4,3,1,3,5,6], '0000ff'
  #     lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
  #     lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
  #     lc.axis :y, :range => [0,6], :color => 'ff00ff', :font_size => 16, :alignment => :center
  #     lc.axis :x, :range => [0,6], :color => '00ffff', :font_size => 16, :alignment => :center
  #
  #     # Line XY Chart
  #     lcxy =  GoogleChart::LineChart.new('320x200', "Line XY Chart", true)
  #     lcxy.data "Trend 1", [[1,1], [2,2], [3,3], [4,4]], '0000ff'
  #     lcxy.data "Trend 2", [[4,5], [2,2], [1,1], [3,4]], '00ff00'
  #     puts lcxy.to_url 
  class LineChart < Base
    attr_accessor :is_xy

    # Specify the 
    # * +chart_size+ in WIDTHxHEIGHT format
    # * +chart_title+ as a string
    # * +is_xy+ is <tt>false</tt> by default. Set it to <tt>true</tt> if you want to plot a Line XY chart
    def initialize(chart_size='300x200', chart_title=nil, is_xy=false) # :yield: self
      super(chart_size, chart_title)
      self.is_xy = is_xy
      @line_styles = []
      yield self if block_given?
    end

    # Pass in <tt>true</tt> here to create a Line XY.
    #
    # Note: This must be done before passing in any data to the chart
    def is_xy=(value)
      @is_xy = value
      if value
        self.chart_type = :lxy
      else
        self.chart_type = :lc
      end
    end

    # Defines a line style. Applicable for line charts.
    # [+data_set_index+] Can be one of <tt>:background</tt> or <tt>:chart</tt> depending on the kind of fill requested
    # [+options+] : Options for the style, specifying things like line thickness and lengths of the line segment and blank portions
    #
    # ==== Options
    # * <tt>:line_thickness</tt> (mandatory) option which specifies the thickness of the line segment in pixels
    # * <tt>:length_segment</tt>, which specifies the length of the line segment
    # * <tt>:length_blank</tt>, which specifies the lenght of the blank segment
    def line_style(data_set_index, options={})
      @line_styles[data_set_index] = "#{options[:line_thickness]}"
      @line_styles[data_set_index] += ",#{options[:length_segment]},#{options[:length_blank]}" if options[:length_segment]
    end

    def process_data
      if self.is_xy or @data.size > 1
        if self.is_xy # XY Line graph data series
          encoded_data = []
          @data.size.times { |i|
            # Interleave X and Y co-ordinate data
            encoded_data << join_encoded_data([encode_data(x_data[i],max_x_value), encode_data(y_data[i],max_y_value)])
          }
          join_encoded_data(encoded_data)
        else # Line graph multiple data series          
          join_encoded_data(@data.collect { |series|
                              encode_data(series, max_data_value)
                            })
        end
      else
        encode_data(@data.flatten, max_data_value)
      end
    end
  end
end
