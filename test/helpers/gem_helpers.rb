module GemHelpers
  def regenerate_index
    FileUtils.rm_rf(
      %w[server/cache/*
      server/*specs*
      server/quick
      server/specifications
      server/source_index].map { |d| Dir[d] })
  end

  def create_gem(*owners_and_or_opts)
    opts, owners = owners_and_or_opts.extract_options!, owners_and_or_opts
    @rubygem = create(:rubygem, :name => opts[:name] || generate(:name))
    create(:version, :rubygem => @rubygem)
    owners.each { |owner| @rubygem.ownerships.create(:user => owner) }
  end

  def gem_specification_from_gem_fixture(name)
    Gem::Package.new(File.join('test', 'gems', "#{name}.gem")).spec
  end

  def stub_uploaded_token(gem_name, token, status = [200, "Success"])
    WebMock.stub_request(:get, "http://#{gem_name}.rubyforge.org/migrate-#{gem_name}.html").
      to_return(:body => token + "\n", :status => status)
  end

  def gem_spec(opts = {})
    Gem::Specification.new do |s|
      s.name = %q{test}
      s.version = opts[:version] || "0.0.0"
      s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
      s.authors = ["Joe User"]
      s.description = %q{This is my awesome gem.}
      s.email = %q{joe@user.com}
      s.licenses = %w(MIT BSD)
      s.requirements = %w(Opencv)
      s.files = [
        "README.textile",
        "Rakefile",
        "VERSION.yml",
        "lib/test.rb",
        "test/test_test.rb"
      ]
      s.homepage = %q{http://user.com/test}
    end
  end

  def gem_file(name = "test-0.0.0.gem")
    File.open(File.expand_path("../gems/#{name}", __FILE__))
  end
end
