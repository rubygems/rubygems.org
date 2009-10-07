class Download < ActiveRecord::Base
  include Pacecar
  attr_accessor :raw
  belongs_to :version, :counter_cache => true

  def perform
    rubygem_name, version_number = self.raw.split('-')

    rubygem = Rubygem.find_by_name(rubygem_name)
    version = rubygem.versions.find_by_number(version_number)

    Download.transaction do
      self.version = version
      self.save!
      rubygem.increment!(:downloads)
    end
  end
end
