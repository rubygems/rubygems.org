namespace :compact_index do
  desc 'Fill Versions rubygem_version and info_checksum attributes for compact index format'
  task migrate: :environment do
    Version.joins(:rubygem).where(rubygems_version: nil).find_in_batches.each do |v|
      rubygem_version = rubygem_version(v.rubygem.name, v.number, v.platform)
      v.update_attribute :rubygems_version, rubygem_version
    end

    Rubygem.all.find_in_batches.each do |rubygem|
      cs = Digest::MD5.hexdigest(CompactIndex.info(rubygem.compact_index_info))
      rubygem.versions.each do |version|
        version.update_attribute :info_checksum, cs
      end
    end
  end
end

def rubygem_version(name, version, platform)
  full_name = "#{name}-#{version}"
  full_name << "-#{platform}" if platform != 'ruby'

  base = "http://production.s3.rubygems.org"
  url = "#{base}/quick/Marshal.4.8/#{full_name}.gemspec.rz"
  begin
    result = fetch(url)
    spec = Marshal.load(Gem.inflate(result))
    spec.rubygems_version.to_s
  rescue => e
    puts e
    puts full_name
  end
end

def fetch(url, redirects = 0, tries = 0)
  fail "Too many redirects #{url}" if redirects >= 3
  fail "Could not download #{url}" if tries >= 3

  uri = URI.parse(url)
  response = nil
  begin
    response = Net::HTTP.get_response(uri)
  rescue StandardError => e
    puts "#{e} #{url}"
  end

  case response
  when Net::HTTPRedirection
    AddRubygemsVersionToVersions.fetch(response["location"], redirects + 1)
  when Net::HTTPSuccess
    response.body
  else
    exp = tries - 1
    sleep(2**exp) if exp > 0
    AddRubygemsVersionToVersions.fetch(url, redirects, tries + 1)
  end
end
