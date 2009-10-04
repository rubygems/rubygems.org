require File.dirname(__FILE__) + '/base'
module GoogleChart
    # Generates a Venn Diagram.
    #        
    # Supply three vd.data statements of label, size, color for circles A, B, C. Then, intersections with four values:
    # * the first value specifies the area of A intersecting B
    # * the second value specifies the area of B intersecting C
    # * the third value specifies the area of C intersecting A
    # * the fourth value specifies the area of A intersecting B intersecting C
    #
    #      vd = GoogleChart::VennDiagram.new("320x200", 'Venn Diagram') 
    #      vd.data "Blue", 100, '0000ff'
    #      vd.data "Green", 80, '00ff00'
    #      vd.data "Red",   60, 'ff0000'
    #      vd.intersections 30,30,30,10
    #      puts vd.to_url  
    class VennDiagram < Base
      
        # Initializes the Venn Diagram with a +chart_size+ (in WIDTHxHEIGHT format) and a +chart_title+
        def initialize(chart_size='300x200', chart_title=nil) # :yield: self
            super(chart_size, chart_title)
            self.chart_type = :v
            @intersections = []
            yield self if block_given? 
        end
         
        def process_data          
          encode_data(@data + @intersections)
        end
         
        # Specify the intersections of the circles in the Venn Diagram. See the Rdoc for class for sample
        def intersections(*values)            
          @intersections = values
        end
    end
end