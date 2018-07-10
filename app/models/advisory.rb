class Advisory < ApplicationRecord
  belongs_to :user
  belongs_to :version

  validates :user, :version, :message, presence: true

  def self.update?
    new_sha = `git ls-remote http://github.com/rubysec/ruby-advisory-db refs/heads/master`.split.first
    if !Dir.exist?('tmp/advisories')
      Dir.mkdir('tmp/advisories')
      Dir.chdir(Rails.root.join('tmp', 'advisories'))
      if system "git clone  --depth 1 http://github.com/rubysec/ruby-advisory-db #{Dir.pwd}/ruby-advisory-db"
        File.write('advisory_db_head_sha', new_sha)
      end
    else
      Dir.chdir(Rails.root.join('tmp', 'advisories'))
      clone_sha = File.open('advisory_db_head_sha', &:readline)
      return false unless new_sha != clone_sha
      advisory_db_path = Rails.root.join('tmp', 'advisories', 'ruby-advisory-db')
      url = "http://github.com/rubysec/ruby-advisory-db"
      File.write('advisory_db_head_sha', new_sha) if system "rm -rf #{advisory_db_path} && git clone  --depth 1 #{url} #{advisory_db_path}"
    end
  end

  def self.find_vulnerability(version, ignored_cves)
    version_advisory_files = []
    Dir.chdir(Rails.root.join('tmp', 'advisories', 'ruby-advisory-db'))
    if Dir.exist?("gems/#{version.rubygem.name}")
      Dir.glob("gems/#{version.rubygem.name}/*.yml") do |advisory|
        version_advisory_files << advisory if contain?(advisory, version)
      end
    end
    find_details(version, version_advisory_files, ignored_cves)
  end

  def self.find_details(_version, version_advisory_files, ignored_cves)
    details = []
    version_advisory_files.each do |advisory|
      File.open(advisory) do |_f|
        advisory = YAML.load_file(advisory)
        details << { title: advisory['title'], url: advisory['url'] } unless ignored_cves.include? advisory['cve']
      end
    end
    details
  end

  def self.contain?(advisory, version)
    advisory = YAML.load_file(advisory)
    version_array = Array.new(1, version.number)
    remove_unaffected_versions(version_array, (advisory['patched_versions'].to_a + advisory['unaffected_versions'].to_a).flatten).present?
  end

  def self.mark_versions
    advisory = {}
    count = 0
    Dir.chdir(Rails.root.join('tmp', 'advisories', 'ruby-advisory-db'))
    ActiveRecord::Base.transaction do
      Dir.glob("/gems/**/*.yml") do |advisory_file|
        advisory = YAML.load_file(advisory_file)
        rubygem = Rubygem.find_by(name: vuln['gem'])
        unless rubygem.nil?
          all_versions = rubygem.versions
          version_number_list = all_versions.pluck(:number)
          unaffected_versions = (advisory['patched_versions'].to_a + advisory['unaffected_versions'].to_a).flatten
          vulnerable_versions = remove_unaffected_versions(version_number_list, unaffected_versions)
          count += all_versions.where(number: vulnerable_versions, vulnerable: false).update_all(vulnerable: true)
        end
      end
    end
    "Versions are successfully marked as vulnerable. #{count} new advisories marked."
  rescue StandardError
    system "rm -rf #{Rails.root.join('tmp', 'advisories')}"
    "Error: Could not update versions"
  end

  def self.remove_unaffected_versions(version_number_list, unaffected_versions)
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
        version_number_list.delete_if { |v| Gem::Version.new(v) >= Gem::Version.new(unaffected_version_number) }
      when "<="
        version_number_list.delete_if { |v| Gem::Version.new(v) <= Gem::Version.new(unaffected_version_number) }
      when "~>"
        version_number_list.delete_if { |v| Gem::Version.new(v) == Gem::Version.new(unaffected_version_number) }
      when ">"
        version_number_list.delete_if { |v| Gem::Version.new(v) > Gem::Version.new(unaffected_version_number) }
      when "<"
        version_number_list.delete_if { |v| Gem::Version.new(v) < Gem::Version.new(unaffected_version_number) }
      end
    end
    version_number_list
  end
end
