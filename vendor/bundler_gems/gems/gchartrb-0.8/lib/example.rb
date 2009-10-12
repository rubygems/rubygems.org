require 'google_chart'

# Some examples from http://24ways.org/2007/tracking-christmas-cheer-with-google-charts

# Pie Chart
pc = GoogleChart::PieChart.new("600x300", "Food and Drinks Consumed Christmas 2007")
pc.data "Egg nog", 10, '00AF33' 
pc.data "Christmas Ham", 20, '4BB74C'
pc.data "Milk (not including egg nog)",	8, 'EE2C2C'
pc.data "Cookies", 25, 'CC3232'
pc.data "Roasted Chestnuts", 5, '33FF33'
pc.data "Chocolate", 3, '66FF66'
pc.data "Various Other Beverages", 15, '9AFF9A'
pc.data "Various Other Foods", 9, 'C1FFC1'
pc.data "Snacks",	5, 'CCFFCC'
puts pc

#  Line Chart
x_axis_labels = (1..31).to_a.collect do |v|    
  if [1,6,25,26,31].member?(v)
    if v == 1
      "Dec 1st"
    elsif v == 31
      "Dec 31st"
    elsif v 
      "#{v}th" 
    end    
  else
    nil
  end  
end 

y_axis_labels = (0..10).to_a.collect do |v|
  val = 10 * v
  if val ==50 or val == 100
    val.to_s
  else
    nil
  end
end

series_1_y = [30,45,20,50,15,80,60,70,40,55,80]
series_2_y = [50,10,30,55,60]

series_1_x = [1,6,8,10,18,23,25,26,28,29,31]
series_2_x = [1,4,6,9,11]

series_1_xy = []
series_2_xy = []

series_1_x.each_with_index do |v,i|
  series_1_xy[i] = [v-1, series_1_y[i] ]
end

series_2_x.each_with_index do |v,i|
  series_2_xy[i] = [v-1, series_2_y[i ] ]
end

lcxy = GoogleChart::LineChart.new('800x300', "Projected Christmas Cheer for 2007", true)
lcxy.data "2006", series_1_xy, '458B00'
lcxy.data "2007", series_2_xy, 'CD2626'
lcxy.max_value [30,100]
lcxy.data_encoding = :text
lcxy.axis :x, :labels => x_axis_labels
lcxy.axis :y, :labels => y_axis_labels
lcxy.grid :x_step => 3.333, :y_step => 10, :length_segment => 1, :length_blank => 3
puts lcxy.to_url


# Plotting a sparklines chart
sparklines = GoogleChart::LineChart.new('100x40', nil, false)
sparklines.data "Test", [4,3,2,4,6,8,10]
sparklines.show_legend = false
sparklines.axis :x, :labels => []
sparklines.axis :y, :labels => []
puts sparklines.to_url(:chxs => "0,000000,10,0,_|1,000000,10,0,_")


