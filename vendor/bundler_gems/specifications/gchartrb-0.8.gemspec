# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gchartrb}
  s.version = "0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Deepak Jois"]
  s.date = %q{2008-03-19}
  s.description = %q{Visit http://code.google.com/p/gchartrb to track development regarding gchartrb.  == FEATURES:  * Provides an object oriented interface in Ruby to create Google Chart URLs for charts.  == INSTALL:  === Ruby Gem:}
  s.email = %q{deepak.jois@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["CREDITS", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "TODO", "lib/example.rb", "lib/google_chart.rb", "lib/google_chart/bar_chart.rb", "lib/google_chart/base.rb", "lib/google_chart/line_chart.rb", "lib/google_chart/pie_chart.rb", "lib/google_chart/scatter_chart.rb", "lib/google_chart/venn_diagram.rb", "lib/google_chart/financial_line_chart.rb", "lib/test.rb"]
  s.homepage = %q{http://code.google.com/p/gchartrb}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{gchartrb}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Ruby Wrapper for the Google Chart API}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
