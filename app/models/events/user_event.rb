class Events::UserEvent < ApplicationRecord
  belongs_to :user, class_name: "::User"
  belongs_to :ip_address, optional: true
end
