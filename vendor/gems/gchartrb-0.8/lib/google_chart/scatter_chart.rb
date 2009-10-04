require File.dirname(__FILE__) + '/base'
module GoogleChart
  
  # Generates a Scatter chart.
  # 
  # ==== Example
  #      sc = GoogleChart::ScatterChart.new('320x200',"Scatter Chart")
  #      sc.data "Scatter Set", [[1,1,], [2,2], [3,3], [4,4]]
  #      sc.point_sizes [10,15,30,55]
  #      puts sc.to_url  
  class ScatterChart < Base
    
    # Initializes the Scatter Chart with a +chart_size+ (in WIDTHxHEIGHT format) and a +chart_title+
    def initialize(chart_size='300x200', chart_title=nil) # :yield: self
      super(chart_size, chart_title)
      self.chart_type = :s
      self.show_legend = false
      @point_sizes = []
      yield self if block_given?
    end
    
    def process_data
      # Interleave X and Y co-ordinate data
      encoded_data = join_encoded_data([encode_data(x_data[0],max_x_value), encode_data(y_data[0],max_y_value)])
      # Add point sizes data if it exists
      unless @point_sizes.empty?
        encoded_data = join_encoded_data([encoded_data, encode_data(@point_sizes)])
      end
      return encoded_data
    end
    
    # Specify the data point sizes of the Scatter chart (optional). The data point sizes are scaled with this data set.
    def point_sizes(values)            
      @point_sizes = values
    end
    
  end
end