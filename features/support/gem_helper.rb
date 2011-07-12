module GemHelper
  def build_gemspec(gemspec)
    builder = Gem::Builder.new(gemspec)
    builder.ui = Gem::SilentUI.new
    builder.build
  end

  def build_gem(name, version, summary = "Gemcutter", platform = "ruby")
    build_gemspec(new_gemspec(name, version, summary, platform))
  end

  def new_gemspec(name, version, summary, platform)
    gemspec = Gem::Specification.new do |s|
      s.name = name
      s.platform = platform
      s.version = "#{version}"
      s.authors = ["John Doe"]
      s.date = "#{Time.now.strftime('%Y-%m-%d')}"
      s.description = "#{summary}"
      s.email = "john.doe@example.org"
      s.files = []
      s.homepage = "http://example.org/#{name}"
      s.require_paths = ["lib"]
      s.rubygems_version = %q{1.3.5}
      s.summary = "#{summary}"
      s.test_files = []
    end

    def gemspec.validate
      "not validating on purpose"
    end

    gemspec
  end
end

World(GemHelper)
