class Download < ActiveRecord::Base
  include Pacecar
  attr_accessor :raw
  belongs_to :version, :counter_cache => true

  def perform
    self.raw.chomp!(".gem")
    version_number = self.raw.split('-').find { |str| Gem::Version.correct?(str) }
    rubygem_name, raw_platform = self.raw.split("-#{version_number}")
    platform = raw_platform.blank? ? "ruby" : raw_platform[1..-1]

    rubygem = Rubygem.find_by_name!(rubygem_name)
    version = rubygem.versions.find_by_number_and_platform!(version_number, platform)

    Download.transaction do
      self.version = version
      self.save!
      rubygem.increment!(:downloads)
    end
  end
end
