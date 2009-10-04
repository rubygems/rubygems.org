require File.dirname(__FILE__) + '/base'
module GoogleChart
    class PieChart < Base
        
        # set to <tt>true</tt> or <tt>false</tt> to indicate if this is a 3d chart
        attr_accessor :is_3d
        
        # set to <tt>true</tt> or <tt>false</tt> to show or hide pie chart labels
        attr_accessor :show_labels

        # Initializes a Pie Chart object with a +chart_size+ and +chart_title+. Specify <tt>is_3d</tt> as +true+ to generate a 3D Pie chart
        def initialize(chart_size='300x200', chart_title=nil, is_3d = false) # :yield: self
            super(chart_size, chart_title)
            self.is_3d = is_3d
            self.show_legend = false
            self.show_labels = true
            yield self if block_given?
        end

        # Set this value to <tt>true</tt> if you want the Pie Chart to be rendered as a 3D image
        def is_3d=(value)
            if value
                self.chart_type = :p3
            else
                self.chart_type = :p
            end
        end

        def process_data
            encode_data(@data, max_data_value)
        end
    end
end