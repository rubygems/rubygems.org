PATH=File.expand_path("~/Projects/ruby-advisory-db")

vulnerabilities = Dir['/home/ylecuyer/Projects/ruby-advisory-db/gems/**/*.yml']
  .map { _1.split('/')[-2..] }
  .each_with_object({}) { |elt, hash| hash[elt[0]] ||= []; hash[elt[0]] << elt[1] }

vulnerabilities.each do |gem_name, cves|
  puts gem_name
  gem = Rubygem.where(name: gem_name).first
  next unless gem

  gem.versions.update_all(cve_count: 0)

  cves.each do |cve|
    patched_versions = YAML.load_file("#{PATH}/gems/#{gem_name}/#{cve}").dig("patched_versions", -1)&.split(',')

    gem.versions.each do |version|
      version.cve_count += 1 if patched_versions.nil? || !Gem::Requirement.new(patched_versions).satisfied_by?(Gem::Version.new(version.number))

      version.save!(validate: false)
    end
  rescue Gem::Requirement::BadRequirementError => e
    puts "Error #{e.class} #{e.message}"
  end
end
