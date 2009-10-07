class Download < ActiveRecord::Base
  include Pacecar
  attr_accessor :raw
  belongs_to :version, :counter_cache => true

  def perform
    rubygem_name, version_number, platform = self.raw.split('-')

    rubygem = Rubygem.find_by_name(rubygem_name)
    version = rubygem.versions.find_by_number_and_platform(version_number, platform || "ruby")

    Download.transaction do
      self.version = version
      self.save!
      rubygem.increment!(:downloads)
    end
  end
end
