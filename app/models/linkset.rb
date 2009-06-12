class Linkset < ActiveRecord::Base
  belongs_to :rubygem
  attr_protected :rubygem_id

  LINKS = %w(home wiki docs mail code bugs)

  LINKS.each do |url|
    validates_url_format_of url, :allow_nil => true, :allow_blank => true
  end

  def empty?
    LINKS.map { |link| attributes[link] }.all?(&:blank?)
  end
end
