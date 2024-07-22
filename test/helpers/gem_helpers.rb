module GemHelpers
  def gem_specification_from_gem_fixture(name)
    Gem::Package.new(File.join("test", "gems", "#{name}.gem")).spec
  end

  def gem_file(name = "test-0.0.0.gem", &)
    Rails.root.join("test", "gems", name.to_s).open("rb", &)
  end

  def build_gemspec(gemspec)
    Gem::DefaultUserInteraction.use_ui(Gem::StreamUI.new(StringIO.new, StringIO.new)) do
      Gem::Package.build(gemspec, true)
    end
  end

  def build_gem(name, version, summary = "Gemcutter", platform = "ruby", &)
    build_gemspec(new_gemspec(name, version, summary, platform, &))
  end

  def build_gem_raw(file_name:, spec:, contents_writer: nil)
    package = Gem::Package.new file_name

    File.open(file_name, "wb") do |file|
      Gem::Package::TarWriter.new(file) do |gem|
        gem.add_file "metadata.gz", 0o444 do |io|
          package.gzip_to(io) do |gz_io|
            gz_io.write spec
          end
        end
        gem.add_file "data.tar.gz", 0o444 do |io|
          package.gzip_to io do |gz_io|
            Gem::Package::TarWriter.new gz_io do |data_tar|
              contents_writer[data_tar] if contents_writer
            end
          end
        end
      end
    end
  end

  def new_gemspec(name, version, summary, platform, extra_args = {})
    ruby_version = extra_args[:ruby_version]
    rubygems_version = extra_args[:rubygems_version]
    Gem::Specification.new do |s|
      s.name = name
      s.platform = platform
      s.version = version.to_s
      s.authors = ["Someone"]
      s.date = Time.zone.now.strftime("%Y-%m-%d")
      s.description = summary.to_s
      s.email = "someone@example.com"
      s.files = []
      s.homepage = "http://example.com/#{name}"
      s.require_paths = ["lib"]
      s.summary = summary.to_s
      s.test_files = []
      s.licenses = []
      s.required_ruby_version = ruby_version
      s.required_rubygems_version = rubygems_version
      s.metadata = { "foo" => "bar" }
      yield s if block_given?
    end
  end
end
