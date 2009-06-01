class Linkset < ActiveRecord::Base
  belongs_to :rubygem

  %w(home wiki docs mail code bugs).each do |url|
    validates_url_format_of url, :allow_nil => true
  end
end
