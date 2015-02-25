module GemHelpers
  def gem_specification_from_gem_fixture(name)
    Gem::Package.new(File.join('test', 'gems', "#{name}.gem")).spec
  end

  def gem_file(name = "test-0.0.0.gem")
    Rails.root.join("test/gems/#{name}").open
  end

  def build_gemspec(gemspec)
    Gem::DefaultUserInteraction.use_ui(Gem::StreamUI.new(StringIO.new, StringIO.new)) do
      Gem::Package.build(gemspec)
    end
  end

  def build_gem(name, version, summary = "Gemcutter", platform = "ruby", &block)
    build_gemspec(new_gemspec(name, version, summary, platform, &block))
  end

  def new_gemspec(name, version, summary, platform)
    gemspec = Gem::Specification.new do |s|
      s.name = name
      s.platform = platform
      s.version = "#{version}"
      s.authors = ["Someone"]
      s.date = Time.now.utc.strftime('%Y-%m-%d')
      s.description = "#{summary}"
      s.email = "someone@example.com"
      s.files = []
      s.homepage = "http://example.com/#{name}"
      s.require_paths = ["lib"]
      s.summary = "#{summary}"
      s.test_files = []
      s.licenses = []
      s.metadata = { "foo" => "bar" }
      yield s if block_given?
    end

    def gemspec.validate
      "not validating on purpose"
    end

    gemspec
  end
end
