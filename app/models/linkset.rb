class Linkset < ActiveRecord::Base
  belongs_to :rubygem
  attr_protected :rubygem_id

  LINKS = %w(home wiki docs mail code bugs).freeze

  LINKS.each do |url|
    validates_url_format_of url, :allow_nil => true, :allow_blank => true
  end

  def empty?
    LINKS.map { |link| attributes[link] }.all?(&:blank?)
  end

  def update_attributes_from_gem_specification!(spec)
    self.update_attributes!(:home => spec.homepage)
  end
end
