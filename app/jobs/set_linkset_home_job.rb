# frozen_string_literal: true

class SetLinksetHomeJob < ApplicationJob
  queue_as :default

  def perform(version:)
    return unless version.indexed? && version.latest_for_platform?

    gem = RubygemFs.instance.get("gems/#{version.gem_file_name}")
    package = Gem::Package.new(StringIO.new(gem))
    homepage = package.spec.homepage

    version.rubygem.linkset ||= Linkset.new
    version.rubygem.linkset.update!(home: homepage)
  end
end
