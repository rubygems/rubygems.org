class Events::RubygemEvent < ApplicationRecord
  belongs_to :rubygem
  belongs_to :ip_address, optional: true
end
