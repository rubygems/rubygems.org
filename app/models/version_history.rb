class VersionHistory < ActiveRecord::Base
  belongs_to :version

  def self.for(version, day)
    VersionHistory.where(version_id: version.id, day: day).first
  end

  def self.make(version, day, count)
    VersionHistory.create(version_id: version.id,
                          day: day.to_s,
                          count: count.to_i).save
  end
end
