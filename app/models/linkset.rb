class Linkset < ActiveRecord::Base
  belongs_to :rubygem
  attr_protected :rubygem_id

  %w(home wiki docs mail code bugs).each do |url|
    validates_url_format_of url, :allow_nil => true, :allow_blank => true
  end
end
