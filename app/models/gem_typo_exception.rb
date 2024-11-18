class GemTypoException < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validate :rubygems_name

  private

  def rubygems_name
    gem = Rubygem.new(name: name)
    errors.add :name, "Rubygem validation failed: #{gem.errors.full_messages}" if gem.invalid?(:typo_exception)
  end
end
