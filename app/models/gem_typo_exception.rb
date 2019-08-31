class GemTypoException < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validate :rubygems_name

  private

  def rubygems_name
    gem = Rubygem.new(name: name)
    errors.add :name, "Rubygem validation failed: #{gem.errors.full_messages}" if gem.invalid?
  end
end
