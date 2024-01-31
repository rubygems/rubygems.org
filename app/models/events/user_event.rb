class Events::UserEvent < ApplicationRecord
  belongs_to :user, class_name: "::User"
  belongs_to :ip_address, optional: true
  belongs_to :geoip_info, optional: true
end
