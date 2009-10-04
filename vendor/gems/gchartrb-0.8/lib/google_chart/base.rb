require 'uri'

module GoogleChart
  class Base
    BASE_URL = "http://chart.apis.google.com/chart?"
    
    SIMPLE_ENCODING = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.split('');
    COMPLEX_ENCODING_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.'.split('');
    @@complex_encoding = []
    COMPLEX_ENCODING_ALPHABET.each_with_index do |outer,index_outer|
      COMPLEX_ENCODING_ALPHABET.each_with_index do |inner, index_inner|
        @@complex_encoding[index_outer * 64 + index_inner] = outer + inner
      end
    end
    
    SHAPE_MARKERS = {:arrow => "a",
      :cross => "c",
      :diamond => "d",
      :circle => "o",
      :square => "s",
      :vline_segment => "v",
      :vline_full => "V",
      :hline_full => "h",
      :x => "x"
    }

    DEFAULT_LINE_STYLE = '1'

    # Size of the chart in WIDTHxHEIGHT format
    attr_accessor :chart_size 
    
    # Type of the chart. Usually, you do not need to set this yourself
    attr_accessor :chart_type 
    
    # Chart title
    attr_accessor :chart_title
    
    # RRGGBB hex value for the color of the title
    attr_accessor :title_color
    
    # Font size of the title
    attr_accessor :title_font_size
    
    # Data encoding to use. Can be one of <tt>:simple</tt>, <tt>:text</tt> or <tt>:extended</tt> (see http://code.google.com/apis/chart/#chart_data)
    attr_accessor :data_encoding
    
    # A hash of the params used to construct the URL        
    attr_accessor :params
    
    # Set to <tt>true</tt> or <tt>false</tt> to show or hide the chart legend. Not applicable for Scatter Chart.
    attr_accessor :show_legend
    
    def initialize(chart_size, chart_title)
      self.params = Hash.new
      @labels = []
      @data   = []
      @colors = []
      @axis   = []
      @markers = []
      @line_styles = []
      self.chart_size    = chart_size
      self.chart_title   = chart_title
      self.data_encoding = :simple
      self.show_legend   = true
    end
    
    # Generates the URL string that can be used to retrieve the graph image in PNG format.
    # Use this after assigning all the properties to the graph
    # You can pass in additional params as a hash for features that may not have been implemented
    # For e.g
    #      lc = GoogleChart::LineChart.new('320x200', "Line Chart", false)
    #      lc.data "Trend 1", [5,4,3,1,3,5,6], '0000ff'
    #      lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
    #      lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
    #      puts lc.to_url({:chm => "000000,0,0.1,0.11"}) # Single black line as a horizontal marker        
    def to_url(extras={})
      prepare_params
      params.merge!(extras)
      query_string = params.map { |k,v| "#{k}=#{URI.escape(v.to_s).gsub(/%20/,'+').gsub(/%7C/,'|')}" }.join('&')
      BASE_URL + query_string
    end

    # Generates a fully encoded URL string that can be used to retrieve the graph image in PNG format.
    # For less verbose URLs, use the <tt>to_url</tt> method. Use this only if you are doing further
    # processing with the URLs, like passing the URL to a method for downloading the images
    #
    # Use this after assigning all the properties to the graph
    # You can pass in additional params as a hash for features that may not have been implemented
    # For e.g
    #      lc = GoogleChart::LineChart.new('320x200', "Line Chart", false)
    #      lc.data "Trend 1", [5,4,3,1,3,5,6], '0000ff'
    #      lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
    #      lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
    #      puts lc.to_escaped_url({:chm => "000000,0,0.1,0.11"}) # Single black line as a horizontal marker            
    def to_escaped_url(extras={})
      prepare_params
      params.merge!(extras)
      query_string = params.map { |k,v| "#{k}=#{URI.escape(v.to_s)}" }.join('&')
      BASE_URL + query_string
    end
    
    # Adds the data to the chart, according to the type of the graph being generated.
    #
    # [+name+] is a string containing a label for the data.
    # [+value+] is either a number or an array of numbers containing the data. Pie Charts and Venn Diagrams take a single number, but other graphs require an array of numbers
    # [+color+ (optional)] is a hexadecimal RGB value for the color to represent the data
    # 
    # ==== Examples
    #
    # for GoogleChart::LineChart (normal)
    #    lc.data "Trend 1", [1,2,3,4,5], 'ff00ff'
    #
    # for GoogleChart::LineChart (XY chart)
    #    lc.data "Trend 2", [[4,5], [2,2], [1,1], [3,4]], 'ff00ff'
    #
    # for GoogleChart::PieChart
    #    lc.data "Apples", 5, 'ff00ff'
    #    lc.data "Oranges", 7, '00ffff'
    def data(name, value, color=nil)
      @data << value
      @labels << name
      @colors << color if color
    end
    
    # Allows (optional) setting of a max value for the chart, which will be used for data encoding and axis plotting.
    # The value to pass depends on the type of chart
    # * For Line Chart and Bar Charts it should be a single integer or float value
    # * For Scatter Charts and Line XY Charts, you MUST pass an array containing the maximum values for X and Y
    # 
    # ==== Examples
    # For bar charts
    #    bc.max_value 5 # 5 will be used to calculate the relative encoding values
    # For scatter chart
    #    sc.max_value [5,6] # 5 is the max x value and 6 is the max y value
    #
    # Note : MAKE SURE you are passing the right values otherwise an exception will be raised
    def max_value(value)
      if [:lxy, :s].member?(self.chart_type) and value.is_a?(Array)
        @max_x = value.first
        @max_y = value.last
      elsif [:lc,:bhg,:bhs,:bvg,:bvs] and (value.is_a?(Integer) or value.is_a?(Float))
        @max_data = value
      else
        raise "Invalid max value for this chart type"
      end
    end
    
    # Adds a background or chart fill. Call this option twice if you want both a background and a chart fill
    # [+bg_or_c+] Can be one of <tt>:background</tt> or <tt>:chart</tt> depending on the kind of fill requested
    # [+type+] Can be one of <tt>:solid</tt>, <tt>:gradient</tt> or <tt>:stripes</tt>
    # [+options+] : Options depend on the type of fill selected above
    #
    # ==== Options
    # For <tt>:solid</tt> type
    # * A <tt>:color</tt> option which specifies the RGB hex value of the color to be used as a fill. For e.g <tt>lc.fill(:chart, :solid, {:color => 'ffcccc'})</tt>
    #
    # For <tt>:gradient</tt> type
    # * An <tt>:angle</tt>, which is the angle of the gradient between 0(horizontal) and 90(vertical)
    # * A <tt>:color</tt> option which is a 2D array containing the colors and an offset each, which specifies at what point the color is pure where: 0 specifies the right-most chart position and 1 the left-most. e,g <tt>lc.fill :background, :gradient, :angle => 0,  :color => [['76A4FB',1],['ffffff',0]]</tt>
    # 
    # For <tt>:stripes</tt> type
    # * An <tt>:angle</tt>, which is the angle of the stripe between 0(horizontal) and 90(vertical)
    # * A <tt>:color</tt> option which is a 2D array containing the colors and width value each, which must be between 0 and 1 where 1 is the full width of the chart. for e.g <tt>lc.fill :chart, :stripes, :angle => 90, :color => [ ['76A4FB',0.2], ['ffffff',0.2] ]</tt>
    def fill(bg_or_c, type, options = {})
      case bg_or_c
      when :background
        @background_fill = "bg," + process_fill_options(type, options)
      when :chart
        @chart_fill = "c," + process_fill_options(type, options)
      end
    end
    
    # Adds an axis to the graph. Not applicable for Pie Chart (GoogleChart::PieChart) or Venn Diagram (GoogleChart::VennDiagram)
    # 
    # [+type+] is a symbol which can be one of <tt>:x</tt>, <tt>:y</tt>, <tt>:right</tt>, <tt>:top</tt> 
    # [+options+] is a hash containing the options (see below)
    # 
    # ==== Options
    # Not all the options are mandatory.
    # [<tt>:labels</tt>] An array containing the labels for the axis
    # [<tt>:positions</tt>] An Array containing the positions for the labels
    # [<tt>:range</tt>] An array containing 2 elements, the start value and end value
    # 
    # axis styling options have to be specified as follows
    # [<tt>:color</tt>] Hexadecimal RGB value for the color to represent the data for the axis labels
    # [<tt>:font_size</tt>] Font size of the labels in pixels
    # [<tt>:alignment</tt>] can be one of <tt>:left</tt>, <tt>:center</tt> or <tt>:right</tt>
    # 
    # ==== Examples
    #     lc.axis :y, :range => [0,6], :color => 'ff00ff', :font_size => 16, :alignment => :center
    #       
    def axis(type, options = {})
      raise "Illegal axis type" unless [:x, :y, :right, :top].member?(type)          
      @axis << [type, options]
    end
    
    # Adds a grid to the graph. Applicable only for Line Chart (GoogleChart::LineChart) and Scatter Chart (GoogleChart::ScatterChart)
    #
    # [+options+] is a hash containing the options (see below) 
    #
    # === Options
    # [<tt>:xstep</tt>] X axis step size
    # [<tt>:ystep</tt>] Y axis step size
    # [<tt>:length_segment</tt> (optional)] Length of the line segement. Useful with the :length_blank value to have dashed lines
    # [<tt>:length_blank</tt> (optional)] Length of the blank segment. use 0 if you want a solid grid
    # 
    # === Examples
    #     lc.grid :x_step => 5, :y_step => 5, :length_segment => 1, :length_blank => 0
    #        
    def grid(options={})
      @grid_str = "#{options[:x_step].to_f},#{options[:y_step].to_f}"
      if options[:length_segment] or options[:length_blank]
        @grid_str += ",#{options[:length_segment].to_f},#{options[:length_blank].to_f}"
      end
    end
    
    # Defines a horizontal or vertical range marker. Applicable for line charts and vertical charts
    #
    # [+alignment+] can be <tt>:horizontal</tt> or <tt>:vertical</tt>
    # [+options+] specifies the color, start point and end point
    # 
    # ==== Options
    # [<tt>:color</tt>] RRGGBB hex value for the color of the range marker
    # [<tt>:start_point</tt>]  position on the x-axis/y-axis at which the range starts where 0.00 is the left/bottom and 1.00 is the right/top
    # [<tt>:end_point</tt>]  position on the x-axis/y-axis at which the range ends where 0.00 is the left/bottom and 1.00 is the right/top
    #
    # ==== Examples
    #     lc.range_marker :horizontal, :color => 'E5ECF9', :start_point => 0.1, :end_point => 0.5
    #     lc.range_marker :vertical, :color => 'a0bae9', :start_point => 0.1, :end_point => 0.5
    def range_marker(alignment, options={}) 
      raise "Invalid alignment specified" unless [:horizontal, :vertical].member?(alignment)
      str = (alignment == :horizontal ) ? "r" : "R"
      str += ",#{options[:color]},0,#{options[:start_point]},#{options[:end_point]}"
      @markers << str 
    end

    # Defines a shape marker. Applicable for line charts and scatter plots
    #
    # [+type+] can be <tt>:arrow</tt>, <tt>:cross</tt>, <tt>:diamond</tt>, <tt>:circle</tt>, <tt>:square</tt>, <tt>:vline_segment</tt>, <tt>:vline_full</tt>, <tt>:hline_full</tt>, <tt>:x</tt>
    # [+options+] specifies the color, data set index, data point index and size in pixels
    # 
    # ==== Options
    # [<tt>:color</tt>] RRGGBB hex value for the color of the range marker
    # [<tt>:data_set_index</tt>]  the index of the line on which to draw the marker. This is 0 for the first data set, 1 for the second and so on.
    # [<tt>:data_point_index</tt>]  is a floating point value that specifies on which data point of the data set the marker will be drawn. This is 0 for the first data point, 1 for the second and so on. Specify a fraction to interpolate a marker between two points.
    # [<tt>:size</tt>] is the size of the marker in pixels.
    #
    # ==== Examples
    #     lcxy.shape_marker :circle, :color => "000000", :data_set_index => 1, :data_point_index => 2, :pixel_size => 10
    #     lcxy.shape_marker :cross, :color => "E5ECF9", :data_set_index => 0, :data_point_index => 0.5, :pixel_size => 10
    def shape_marker(type, options={})
      raise "Invalid shape marker type specified" unless SHAPE_MARKERS.has_key?(type)
      shape_marker_str = "#{SHAPE_MARKERS[type]},#{options[:color]},#{options[:data_set_index]},#{options[:data_point_index]},#{options[:pixel_size]}"
      @markers << shape_marker_str
    end

    # Defines a Fill area. Applicable for line charts only
    #
    # [+color+] is the color of the fill area
    # [+start_index+] is the index of the line at which the fill starts. This is 0 for the first data set, 1 for the second and so on.
    # [+end_index+] is the index of the line at which the fill ends.
    #
    # ==== Examples
    #     # Fill Area (Multiple Datasets)
    #       lc = GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
    #       lc.show_legend = false
    #       lc.data "Trend 1", [5,5,6,5,5], 'ff0000'
    #       lc.data "Trend 2", [3,3,4,3,3], '00ff00'
    #       lc.data "Trend 3", [1,1,2,1,1], '0000ff'
    #       lc.data "Trend 4", [0,0,0,0,0], 'ffffff'
    #       lc.fill_area '0000ff',2,3
    #       lc.fill_area '00ff00',1,2
    #       lc.fill_area 'ff0000',0,1
    #     end
    #     puts "\nFill Area (Multiple Datasets)"
    #      puts lc.to_url
    #
    #     # Fill Area (Single Dataset)
    #     lc = GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
    #       lc.show_legend = false
    #       lc.data "Trend 1", [5,5,6,5,5], 'ff0000'
    #       lc.fill_area 'cc6633', 0, 0
    #     end
    #     puts "\nFill Area (Single Dataset)"
    #     puts lc.to_url
    #
    def fill_area(color, start_index, end_index)
      if (start_index == 0 and end_index == 0)
        @markers << "B,#{color},0,0,0"
      else
        @markers << "b,#{color},#{start_index},#{end_index},0"
      end
    end
    
    protected

    def prepare_params
      params.clear
      set_size
      set_type
      set_colors
      set_fill_options
      add_axis unless @axis.empty?
      add_grid  
      add_data
      add_line_styles unless @line_styles.empty?
      set_bar_width_spacing_options if @bar_width_spacing_options
      add_markers unless @markers.empty?
      add_labels(@labels) if [:p, :p3].member?(self.chart_type)
      add_legend(@labels) if show_legend
      add_title  if chart_title.to_s.length > 0
    end
    
    def process_fill_options(type, options)
      case type
      when :solid
        "s,#{options[:color]}"
      when :gradient
        "lg,#{options[:angle]}," + options[:color].collect { |o| "#{o.first},#{o.last}" }.join(",")
      when :stripes
        "ls,#{options[:angle]}," + options[:color].collect { |o| "#{o.first},#{o.last}" }.join(",")
      end
      
    end
    
    def set_type
      params.merge!({:cht => chart_type})
    end
    
    def set_size
      params.merge!({:chs => chart_size})
    end
    
    def set_colors
      params.merge!({:chco => @colors.collect{|c| c.downcase}.join(",")  }) if @colors.size > 0
    end
    
    def set_fill_options
      fill_opt = [@background_fill, @chart_fill].compact.join("|")
      params.merge!({:chf => fill_opt}) if fill_opt.length > 0
    end
    
    def add_labels(labels)
      params.merge!({:chl => labels.collect{|l| l.to_s}.join("|") }) if self.show_labels 
    end                
    
    def add_legend(labels)
      params.merge!({:chdl => labels.collect{ |l| l.to_s}.join("|")})
    end
    
    def add_title
      params.merge!({:chtt => chart_title})
      params.merge!({:chts => title_color}) if title_color
      params.merge!({:chts => "#{title_color},#{title_font_size}"}) if title_color and title_font_size
    end
    
    def add_axis          
      chxt = []
      chxl = []
      chxp = []
      chxr = []                       
      chxs = []
      # Process params
      @axis.each_with_index do |axis, idx|
        # Find axis type
        case axis.first
        when :x
          chxt << "x"
        when :y
          chxt << "y"
        when :top
          chxt << "t"
        when :right
          chxt << "r"
        end
        
        # Axis labels
        axis_opts = axis.last
        
        if axis_opts[:labels]
          chxl[idx] = "#{idx}:|" + axis_opts[:labels].join("|")
        end
        
        # Axis positions
        if axis_opts[:positions]
          chxp[idx] = "#{idx}," + axis_opts[:positions].join(",")
        end
        
        # Axis range
        if axis_opts[:range]
          chxr[idx] = "#{idx},#{axis_opts[:range].first},#{axis_opts[:range].last}"                
        end
        
        # Axis Styles
        if axis_opts[:color] or axis_opts[:font_size] or axis_opts[:alignment]
          if axis_opts[:alignment]
            alignment = case axis_opts[:alignment]
                        when :center
                          0
                        when :left
                          -1
                        when :right
                          1 
                        else
                          nil
                        end
          end
          chxs[idx] = "#{idx}," + [axis_opts[:color], axis_opts[:font_size], alignment].compact.join(",")
        end
      end
      
      # Add to params hash
      params.merge!({ :chxt => chxt.join(",") })          unless chxt.empty?
      params.merge!({ :chxl => chxl.compact.join("|") })  unless chxl.compact.empty?
      params.merge!({ :chxp => chxp.compact.join("|") })  unless chxp.compact.empty?
      params.merge!({ :chxr => chxr.compact.join("|") })  unless chxr.compact.empty?
      params.merge!({ :chxs => chxs.compact.join("|") })  unless chxs.compact.empty?
    end
    
    def add_grid
      params.merge!({ :chg => @grid_str }) if @grid_str
    end

    def add_line_styles
      0.upto(@line_styles.length - 1) { |i|
        @line_styles[i] = DEFAULT_LINE_STYLE unless @line_styles[i]
      }
      params.merge!({:chls => @line_styles.join("|")})
    end

    def set_bar_width_spacing_options
      params.merge!({:chbh => @bar_width_spacing_options})
    end
    
    def add_markers
      params.merge!({:chm => @markers.join("|")})
    end

    def add_data
      converted_data = process_data
      case data_encoding
      when :simple
        converted_data = "s:" + converted_data
      when :text
        converted_data = "t:" + converted_data
      when :extended
        converted_data = "e:" + converted_data
      else
        raise "Illegal Encoding Specified"
      end
      params.merge!({:chd => converted_data})
    end
    
    def encode_data(values, max_value=nil)
      case data_encoding
      when :simple
        simple_encode(values, max_value)
      when :text
        text_encode(values, max_value)
      when :extended
        extended_encode(values, max_value)
      else
        raise "Illegal Encoding Specified"
      end
    end
    
    def simple_encode(values, max_value=nil)
      alphabet_length = 61
      max_value = values.max unless max_value

      chart_data = values.collect do |val|              
        if val.to_i >=0
          if max_value == 0  
            SIMPLE_ENCODING[0]
          else
            SIMPLE_ENCODING[(alphabet_length * val / max_value).to_i]
          end
        else
          "_"
        end
      end
      
      return chart_data.join('')
    end
    
    def text_encode(values, max_value=nil)
      max_value = values.max unless max_value
      values.inject("") { |sum, v|
         if max_value == 0
          sum += "0,"
        else
          sum += ( "%.1f" % (v*100/max_value) ) + ","
        end
      }.chomp(",")
    end
    
    def extended_encode(values, max_value)
      max_value = values.max unless max_value
      values.collect { |v|
         if max_value == 0
          @@complex_encoding[0]
        else
          @@complex_encoding[(v * 4095/max_value).to_i]
        end
      }.join('')
    end
    
    def join_encoded_data(encoded_data)
      encoded_data.join((self.data_encoding == :simple or self.data_encoding == :extended) ? "," : "|")
    end
    
    def max_data_value
      @max_data or @data.flatten.max
    end
    
    def max_x_value
      @max_x or x_data.flatten.max
    end

    def max_y_value
      @max_y or y_data.flatten.max
    end

    def x_data
      @data.collect do |series|
        series.collect { |val| val.first }
      end
    end

    def y_data
      @data.collect do |series|
        series.collect { |val| val.last }
      end
    end        
  end
end
