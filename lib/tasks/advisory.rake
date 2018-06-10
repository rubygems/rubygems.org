namespace :advisory do
  public def remove_unaffected(unaffected_versions)
    version_array = []
    unaffected_versions.each do |versions|
      version_array << if versions.split.length > 2
                         versions.split(',')
                       else
                         versions
                       end
    end
    version_array.flatten!
    version_array.each do |versions|
      unaffectedv_array = versions.split
      unaffected_version_number = unaffectedv_array.second
      case unaffectedv_array.first
      when ">="
        delete_if { |v| Gem::Version.new(v) >= Gem::Version.new(unaffected_version_number) }
      when "<="
        delete_if { |v| Gem::Version.new(v) <= Gem::Version.new(unaffected_version_number) }
      when "~>"
        delete_if { |v| Gem::Version.new(v) == Gem::Version.new(unaffected_version_number) }
      when ">"
        delete_if { |v| Gem::Version.new(v) > Gem::Version.new(unaffected_version_number) }
      when "<"
        delete_if { |v| Gem::Version.new(v) < Gem::Version.new(unaffected_version_number) }
      end
    end
  end

  desc 'Mark versions as vulnerable'
  task update: :environment do
    begin
      system "git submodule update"
      vuln = {}
      count = 0
      Dir.chdir(Rails.root.join('storage', 'ruby-advisory-db'))
      ActiveRecord::Base.transaction do
        Dir.glob("**/*.yml") do |gem_name|
          vuln = YAML.load_file(gem_name)
          rubygem = Rubygem.find_by(name: vuln['gem'])
          unless rubygem.nil?
            all_versions = rubygem.versions
            version_number_list = all_versions.pluck(:number)
            version_number_list.remove_unaffected((vuln['patched_versions'].to_a + vuln['unaffected_versions'].to_a).flatten)
            count += all_versions.where(number: version_number_list, vulnerable: false).update_all(vulnerable: true)
          end
        end
      end
      puts "Versions are successfully marked as vulnerable. #{count} new advisories marked."
    rescue StandardError
      puts "Error: Could not update versions"
    end
  end
end
