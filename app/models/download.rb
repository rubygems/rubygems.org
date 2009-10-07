class Download < ActiveRecord::Base
  include Pacecar
  attr_accessor :raw
  belongs_to :version, :counter_cache => true

  def perform
    logger.info "[DOWNLOAD] #{self.raw}"
    rubygem_name = self.raw.split('-').first

    rubygem = Rubygem.find_by_name!(rubygem_name)
    version = Version.find_from_slug!(rubygem.id, self.raw.gsub("#{rubygem_name}-", ""))

    Download.transaction do
      self.version = version
      self.save!
      rubygem.increment!(:downloads)
    end
  end
end
