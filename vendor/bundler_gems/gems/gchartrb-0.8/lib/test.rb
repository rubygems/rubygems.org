require 'google_chart'

# Pie Chart
GoogleChart::PieChart.new('320x200', "Pie Chart",false) do |pc|
  pc.data "Apples", 40
  pc.data "Banana", 20
  pc.data "Peach", 30
  pc.data "Orange", 60
  puts "\nPie Chart"
  puts pc.to_url
  
  # Pie Chart with no labels
  pc.show_labels = false
  puts "\nPie Chart (with no labels)"
  puts pc.to_url  
end


# Line Chart
GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
  lc.data "Trend 1", [5,4,3,1,3,5,6], '0000ff'
  lc.show_legend = true
  lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
  lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
  lc.axis :y, :range => [0,6], :color => 'ff00ff', :font_size => 16, :alignment => :center
  lc.axis :x, :range => [0,6], :color => '00ffff', :font_size => 16, :alignment => :center
  lc.grid :x_step => 100.0/6.0, :y_step => 100.0/6.0, :length_segment => 1, :length_blank => 0
  puts "\nLine Chart"
  puts lc.to_url
end

# Bar Chart
GoogleChart::BarChart.new('800x200', "Bar Chart", :vertical, false) do |bc|
  bc.data "Trend 1", [5,4,3,1,3,5], '0000ff' 
  bc.data "Trend 2", [1,2,3,4,5,6], 'ff0000'
  bc.data "Trend 3", [6,5,4,4,5,6], '00ff00'
  bc.width_spacing_options :bar_width => 5, :bar_spacing => 2, :group_spacing => 10
  puts "\nBar Chart"
  puts bc.to_url
end

# Line XY Chart
line_chart_xy = GoogleChart::LineChart.new('320x200', "Line XY Chart", true) do |lcxy|
  lcxy.data "Trend 1", [[1,1], [2,2], [3,3], [4,4]], '0000ff'
  lcxy.data "Trend 2", [[4,5], [2,2], [1,1], [3,4]], '00ff00'
  puts "\nLine XY Chart (inside a block)"
  puts lcxy.to_url   
end

# Venn Diagram
# Supply three vd.data statements of label, size, color for circles A, B, C
# Then, an :intersections with four values:
# the first value specifies the area of A intersecting B
# the second value specifies the area of B intersecting C
# the third value specifies the area of C intersecting A
# the fourth value specifies the area of A intersecting B intersecting C
GoogleChart::VennDiagram.new("320x200", 'Venn Diagram') do |vd|
  vd.data "Blue", 100, '0000ff'
  vd.data "Green", 80, '00ff00'
  vd.data "Red",   60, 'ff0000'
  vd.intersections 30,30,30,10
  puts "\nVenn Diagram"
  puts vd.to_url
end

# Scatter Chart
GoogleChart::ScatterChart.new('320x200',"Scatter Chart") do |sc|
  sc.data "Scatter Set", [[1,1,], [2,2], [3,3], [4,4]]
  sc.max_value [5,5] # Setting the max value
  sc.axis :x, :range => [0,5]
  sc.axis :y, :range => [0,5], :labels => [0,1,2,3,4,5]
  sc.point_sizes [10,15,30,55] # Optional
  puts "\nScatter Chart"
  puts sc.to_url
end

# Grid Fills
GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
  lc.data "Trend 1", [5,4,3,1,3,5,6], '0000ff'
  lc.show_legend = true
  lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
  lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
  lc.axis :y, :range => [0,6], :color => 'ff00ff', :font_size => 16, :alignment => :center
  lc.axis :x, :range => [0,6], :color => '00ffff', :font_size => 16, :alignment => :center
  lc.grid :x_step => 100.0/6.0, :y_step => 100.0/6.0, :length_segment => 1, :length_blank => 0
  puts "\nLine Chart"
  puts lc.to_url
end

# Solid fill
line_chart_xy.fill(:background, :solid, {:color => 'fff2cc'})
line_chart_xy.fill(:chart, :solid, {:color => 'ffcccc'})
puts "\nLine Chart with Solid Fill"
puts line_chart_xy.to_url

# Gradient fill
line_chart_xy.fill :background, :gradient, :angle => 0,  :color => [['76A4FB',1],['ffffff',0]]
line_chart_xy.fill :chart, :gradient, :angle => 0, :color => [['76A4FB',1], ['ffffff',0]]
puts "\nLine Chart with Gradient Fill"
puts line_chart_xy.to_url

# Stripes Fill
line_chart_xy.fill :chart, :stripes, :angle => 90, :color => [['76A4FB',0.2], ['ffffff',0.2]]
puts "\nLine Chart with Stripes Fill"
puts line_chart_xy.to_url

# Range and Shape Markers
puts "\nLine Chart with range markers and shape markers"  
GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
  lc.title_color = 'ff00ff'
  lc.data "Trend 1", [5,4,3,1,3,5,6], '0000ff'
  lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
  lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
  lc.max_value 10 # Setting max value for simple line chart 
  lc.range_marker :horizontal, :color => 'E5ECF9', :start_point => 0.1, :end_point => 0.5
  lc.range_marker :vertical, :color => 'a0bae9', :start_point => 0.1, :end_point => 0.5
  # Draw an arrow shape marker against lowest value in dataset
  lc.shape_marker :arrow, :color => '000000', :data_set_index => 0, :data_point_index => 3, :pixel_size => 10   
  puts lc.to_url
end

# Bryan Error condition
lcxy =  GoogleChart::LineChart.new('320x200', "Line XY Chart", true)
lcxy.data 'A', [[0, 32], [1, 15], [2, 23], [3, 18], [4, 41],  [5, 53]],'0000ff'
lcxy.data 'B', [[0, 73], [1, 0],  [2, 28], [3, 0],  [4, 333], [5, 0]], '00ff00'
lcxy.data 'C', [[0, 22], [1, 26], [2, 14], [3, 33], [4, 17],  [5, 7]], 'ff0000'
lcxy.data 'D', [[0, 4],  [1, 39], [2, 0],  [3, 5],  [4, 11],  [5, 14]], 'cc00ff'
puts "\nBryan Error Condition"
puts lcxy.to_url

# Stacked Chart error
stacked = GoogleChart::BarChart.new('320x200', "Stacked Chart", :vertical, true)
stacked.data_encoding = :text
stacked.data "Trend 1", [60,80,20], '0000ff' 
stacked.data "Trend 2", [50,5,100], 'ff0000'
stacked.axis :y, :range => [0,120]
stacked.title_color='ff0000'
stacked.title_font_size=18
puts "\nStacked Chart with colored title"
puts stacked.to_url

# Encoding Error (Bar Chart)
bc = GoogleChart::BarChart.new('800x350', nil, :vertical, true) do |chart|
  chart.data_encoding = :extended
      
  chart.data "2^i", (0..8).to_a.collect{|i| 2**i}, "ff0000"
  chart.data "2.1^i", (0..8).to_a.collect{|i| 2.1**i}, "00ff00"
  chart.data "2.2^i", (0..8).to_a.collect{|i| 2.2**i}, "0000ff"
  max = 2.2**8
      
  chart.show_legend = true
  chart.axis :y, :range => [0,max], :font_size => 16, :alignment => :center
  chart.axis :x, :labels => (0..8).to_a, :font_size => 16, :alignment => :center
end

puts "\nBar chart encoding error test"
puts bc.to_url

# Financial Line Chart (Experimental)
flc = GoogleChart::FinancialLineChart.new do |chart|
  chart.data "", [3,10,20,37,40,25,68,75,89,99], "ff0000"
end
puts "\nFinancial Line Chart or Sparklines (EXPERIMENTAL)"
puts flc.to_url

# Line Style
lc = GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
  lc.data "Trend 1", [5,4,3,1,3,5], '0000ff'
  lc.data "Trend 2", [1,2,3,4,5,6], '00ff00'
  lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
  lc.line_style 0, :length_segment => 3, :length_blank => 2, :line_thickness => 3
  lc.line_style 1, :length_segment => 1, :length_blank => 2, :line_thickness => 1
  lc.line_style 2, :length_segment => 2, :length_blank => 1, :line_thickness => 5
end
puts "\nLine Styles"
puts lc.to_url

puts "\nLine Styles (encoded URL)"
puts lc.to_escaped_url

# Fill Area (Multiple Datasets)
lc = GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
  lc.show_legend = false
  lc.data "Trend 1", [5,5,6,5,5], 'ff0000'
  lc.data "Trend 2", [3,3,4,3,3], '00ff00'
  lc.data "Trend 3", [1,1,2,1,1], '0000ff'
  lc.data "Trend 4", [0,0,0,0,0], 'ffffff'
  lc.fill_area '0000ff',2,3
  lc.fill_area '00ff00',1,2
  lc.fill_area 'ff0000',0,1
end
puts "\nFill Area (Multiple Datasets)"
puts lc.to_url

# Fill Area (Single Datasets)
lc = GoogleChart::LineChart.new('320x200', "Line Chart", false) do |lc|
  lc.show_legend = false
  lc.data "Trend 1", [5,5,6,5,5], 'ff0000'
  lc.fill_area 'cc6633', 0, 0
end
puts "\nFill Area (Single Dataset)"
puts lc.to_url
