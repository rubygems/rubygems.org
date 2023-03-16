class YankRubygemService
  def initialize(rubygem:)
    @rubygem = rubygem
  end

  def call
    versions.each do |version|
      security_user.deletions.create!(version: version) unless version.yanked?
    end
  end

  private

  attr_reader :rubygem

  delegate :versions, to: :rubygem

  def security_user
    @_security_user ||= User.find_by!(email: "security@rubygems.org")
  end
end
