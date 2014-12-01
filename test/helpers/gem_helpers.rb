module GemHelpers
  def create_gem(*owners_and_or_opts)
    opts, owners = owners_and_or_opts.extract_options!, owners_and_or_opts
    @rubygem = create(:rubygem, :name => opts[:name] || generate(:name))
    create(:version, :rubygem => @rubygem)
    owners.each { |owner| @rubygem.ownerships.create(:user => owner) }
  end

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

  def new_gemspec(name, version, summary, platform, &block)
    gemspec = Gem::Specification.new do |s|
      s.name = name
      s.platform = platform
      s.version = "#{version}"
      s.authors = ["John Doe"]
      s.date = "#{Time.now.utc.strftime('%Y-%m-%d')}"
      s.description = "#{summary}"
      s.email = "john.doe@example.org"
      s.files = []
      s.homepage = "http://example.org/#{name}"
      s.require_paths = ["lib"]
      s.rubygems_version = %q{1.3.5}
      s.summary = "#{summary}"
      s.test_files = []
      s.licenses = []
      block.call(s) if block
    end

    def gemspec.validate
      "not validating on purpose"
    end

    gemspec
  end
end
