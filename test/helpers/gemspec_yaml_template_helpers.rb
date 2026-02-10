module GemspecYamlTemplateHelpers
  DEFAULTS = {
    name: "test",
    version: "1.0.0",
    date: "1980-01-02",
    authors: ["hello world"],
    summary: "hello world",
    dependencies: [],
    use_yaml_alias: false
  }.freeze

  def gemspec_yaml_template(**options)
    opts = DEFAULTS.merge(options.compact)
    excluded = options.select { |_, v| v.nil? }.keys

    parts = build_yaml_parts(opts, excluded)
    "#{parts.join("\n")}\n"
  end

  private

  def build_yaml_parts(opts, excluded)
    parts = ["--- !ruby/object:Gem::Specification"]
    parts << "name: #{opts[:name]}" unless excluded.include?(:name)
    parts.concat(version_yaml(opts[:version])) unless excluded.include?(:version)
    parts << "platform: ruby"
    parts.concat(authors_yaml(opts[:authors])) unless excluded.include?(:authors)
    parts.concat(static_fields_yaml(opts))
    parts.concat(requirements_yaml(opts[:use_yaml_alias]))
    parts << "requirements: []"
    parts << "rubygems_version: 4.0.0.dev"
    parts << "specification_version: 4"
    parts << "summary: #{opts[:summary]}" unless excluded.include?(:summary)
    parts << "test_files: []"
    parts
  end

  def version_yaml(version)
    [
      "version: !ruby/object:Gem::Version",
      "  version: #{version}"
    ]
  end

  def authors_yaml(authors)
    ["authors:"] + authors.map { |a| "- #{a}" }
  end

  def static_fields_yaml(opts)
    deps = opts[:dependencies]
    [
      "bindir: bin",
      "cert_chain: []",
      "date: #{opts[:date]} 00:00:00.000000000 Z",
      deps.empty? ? "dependencies: []" : (["dependencies:"] + deps).join("\n"),
      "executables: []",
      "extensions: []",
      "extra_rdoc_files: []",
      "files: []",
      "licenses: []",
      "metadata: {}",
      "rdoc_options: []",
      "require_paths:",
      "- lib"
    ]
  end

  def requirements_yaml(use_alias)
    parts = []
    parts << (use_alias ? "required_ruby_version: &1 !ruby/object:Gem::Requirement" : "required_ruby_version: !ruby/object:Gem::Requirement")
    parts << "  requirements:"
    parts << "  - - \">=\""
    parts << "    - !ruby/object:Gem::Version"
    parts << "      version: '0'"

    if use_alias
      parts << "required_rubygems_version: *1"
    else
      parts << "required_rubygems_version: !ruby/object:Gem::Requirement"
      parts << "  requirements:"
      parts << "  - - \">=\""
      parts << "    - !ruby/object:Gem::Version"
      parts << "      version: '0'"
    end
    parts
  end
end
