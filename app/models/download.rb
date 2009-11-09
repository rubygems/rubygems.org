class Download < ActiveRecord::Base
  include Pacecar
  attr_accessor :raw
  belongs_to :version, :counter_cache => true

  def perform
    version = Version.find_by_full_name!(self.raw.chomp(".gem"))

    Download.transaction do
      self.version = version
      self.save!
      self.version.rubygem.increment!(:downloads)
    end
  end
end
