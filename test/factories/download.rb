Factory.define :download do |download|
  download.raw { "somegem-#{Factory.next(:version_number)}" }
end
