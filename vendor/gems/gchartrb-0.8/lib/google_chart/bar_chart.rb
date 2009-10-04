require File.dirname(__FILE__) + '/base'
module GoogleChart
  # Generates a Bar Chart. You can specify the alignment(horizontal or vertical) and whether you want the bars to be grouped or stacked
  # ==== Examples
  #     bc = GoogleChart::BarChart.new('800x200', "Bar Chart", :vertical, false)
  #     bc.data "Trend 1", [5,4,3,1,3,5], '0000ff'     
  class BarChart < Base
    
    attr_accessor :alignment, :stacked
    
    # Specify the 
    # * +chart_size+ in WIDTHxHEIGHT format
    # * +chart_title+ as a string
    # * +alignment+ as either <tt>:vertical</tt> or <tt>:horizontal</tt>
    # * +stacked+ should be +true+ if you want the bars to be stacked, false otherwise
    def initialize(chart_size='300x200', chart_title=nil, alignment=:vertical, stacked=false) # :yield: self
      super(chart_size, chart_title)
      @alignment = alignment
      @stacked = stacked
      set_chart_type
      self.show_legend = true
      yield self if block_given?
    end
    
    # Set the alignment to either <tt>:vertical</tt> or <tt>:horizontal</tt>
    def alignment=(value)
      @alignment = value
      set_chart_type
    end
    
    # If you want the bar chart to be stacked, set the value to <tt>true</tt>, otherwise set the value to <tt>false</tt> to group it.
    def stacked=(value)
      @stacked = value
      set_chart_type
    end

    # Defines options for bar width, spacing between bars and between groups of bars. Applicable for bar charts.
    # [+options+] : Options for the style, specifying things like line thickness and lengths of the line segment and blank portions
    #
    # ==== Options
    # * <tt>:bar_width</tt>, Bar width in pixels
    # * <tt>:bar_spacing</tt> (optional), space between bars in a group
    # * <tt>:group_spacing</tt> (optional), space between groups
    def width_spacing_options(options={})
      options_str = "#{options[:bar_width]}"
      options_str += ",#{options[:bar_spacing]}" if options[:bar_spacing]
      options_str += ",#{options[:group_spacing]}" if options[:bar_spacing] and options[:group_spacing]
      @bar_width_spacing_options = options_str
    end

    def process_data
      if @stacked # Special handling of max value for stacked
        unless @max_data # Unless max_data is explicitly set
          @max_data = @data.inject([]) do |sum_arr, series| 
            series.each_with_index do |v,i| 
              if sum_arr[i] == nil
                sum_arr[i] = v
              else
                sum_arr[i] += v
              end
            end
            sum_arr
          end.max
        end
      end

      if @data.size > 1              
        join_encoded_data(@data.collect { |series|
                            encode_data(series, max_data_value)
                          })
      else
        encode_data(@data.flatten,max_data_value)
      end
    end
    
    private
    def set_chart_type
      # Set chart type
      if alignment == :vertical and stacked == false
        self.chart_type = :bvg
      elsif alignment == :vertical and stacked == true
        self.chart_type = :bvs
      elsif alignment == :horizontal and stacked == false
        self.chart_type = :bhg
      elsif alignment == :horizontal and stacked == true
        self.chart_type = :bhs
      end          
    end
  end
end
