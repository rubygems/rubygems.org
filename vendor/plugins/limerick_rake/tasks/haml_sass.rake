# Dan Croak, February 2008

@css_dir   = "#{RAILS_ROOT}/public/stylesheets"
@sass_dir  = "#{@css_dir}/sass"
@views_dir = "#{RAILS_ROOT}/app/views"

def convert_css_to_sass(basename)
  system "css2sass #{@css_dir}/#{basename}.css > #{@sass_dir}/#{basename}.sass"
end

def convert_sass_to_css(basename)
  system "sass #{@sass_dir}/#{basename}.sass > #{@css_dir}/#{basename}.css"
end

def convert_html_to_haml(controller, basename)
  extname = basename.include?("erb") ? ".html.erb" : ".rhtml"
  basename = basename.split(".").first
  system "html2haml #{@views_dir}/#{controller}/#{basename}#{extname} > #{@views_dir}/#{controller}/#{basename}.html.haml"
  system "rm #{@views_dir}/#{controller}/#{basename}#{extname}"
end

namespace :sass do
  desc "Convert all CSS files to Sass."
  task :all_css2sass => :environment do
    begin
      Dir.mkdir(@sass_dir)
    rescue Exception => e
      nil
    end

    files = Dir.entries(@css_dir).find_all do |f| 
      File.extname("#{@css_dir}/#{f}") == ".css" &&
      File.basename("#{@css_dir}/#{f}") !~ /^[.]/
    end

    files.each do |filename|
      basename = File.basename("#{@css_dir}/#{filename}", ".css")
      convert_css_to_sass basename
      convert_sass_to_css basename
    end
  end
  
  desc "Convert all Sass files to CSS."
  task :all_sass2css => :environment do
    files = Dir.entries(@sass_dir).find_all do |f| 
      File.extname("#{@sass_dir}/#{f}") == ".sass" &&
      File.basename("#{@sass_dir}/#{f}") !~ /^[.]/
    end

    files.each do |filename|
      basename = File.basename("#{@sass_dir}/#{filename}", ".sass")
      convert_sass_to_css basename
    end
  end
end

namespace :haml do
  desc "Convert all HTML files to Haml."
  task :all_html2haml => :environment do
    controllers = Dir.entries(@views_dir).find_all do |c| 
      File.directory?("#{@views_dir}/#{c}") &&
      File.basename("#{@views_dir}/#{c}") !~ /^[.]/
    end

    controllers.each do |controller|
      files = Dir.entries("#{@views_dir}/#{controller}").find_all do |f|
        (File.new("#{@views_dir}/#{controller}/#{f}").path.include?(".html.erb") ||
         File.new("#{@views_dir}/#{controller}/#{f}").path.include?(".rhtml")) &&
        File.basename("#{@views_dir}/#{controller}/#{f}") !~ /^[.]/
      end
      files.each do |filename|
        basename = File.basename("#{@views_dir}/#{controller}/#{filename}")
        convert_html_to_haml controller, basename
      end
    end
  end
end

