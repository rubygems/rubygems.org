desc 'Renames all .rhtml views to .html.erb, .rjs to .js.rjs, .rxml to .xml.builder and .haml to .html.haml'
namespace :rails_two do
  task :rename_views do
    Dir.glob('app/views/**/[^_]*.rhtml').each do |file|
      puts `git mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end

    Dir.glob('app/views/**/[^_]*.rjs').each do |file|
      puts `git mv #{file} #{file.gsub(/\.rjs$/, '.js.rjs')}`
    end

    Dir.glob('app/views/**/[^_]*.rxml').each do |file|
      puts `git mv #{file} #{file.gsub(/\.rxml$/, '.xml.builder')}`
    end

    Dir.glob('app/views/**/[^_]*.haml').each do |file|
      puts `git mv #{file} #{file.gsub(/\.haml$/, '.html.haml')}`
    end
  end
end