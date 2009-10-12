%w(
    base
    pie_chart
    line_chart
    bar_chart
    venn_diagram
    scatter_chart
    financial_line_chart    
).each do |filename|
    require File.dirname(__FILE__) + "/google_chart/#{filename}"
end
