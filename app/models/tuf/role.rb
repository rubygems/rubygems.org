require 'pp'

require 'tuf/role/metadata'
require 'tuf/role/targets'
require 'tuf/role/root'

module Tuf
  module Role
    def from_hash(content)
      case content['_type']
      when 'Root'      then Tuf::Role::Root
      when 'Targets'   then Tuf::Role::Targets
      when 'Release'   then Tuf::Role::Release
      when 'Timestamp' then Tuf::Role::Timestamp
      else raise("Unknown role: #{content.pretty_inspect}")
      end.new(content)
    end
    module_function :from_hash
  end
end
