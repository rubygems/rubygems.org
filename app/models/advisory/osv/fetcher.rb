# frozen_string_literal: true

class Advisory::OSV::Fetcher < Advisory::Fetcher
  def self.feature_flag = FeatureFlag::OSV_ADVISORIES
  def self.advisory_class = Advisory::OSV

  def map(document)
    Advisory::OSV::Mapper.call(document)
  end
end
