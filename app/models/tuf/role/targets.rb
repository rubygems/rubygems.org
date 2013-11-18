require 'tuf/key'
require 'tuf/signer'

module Tuf
  module Role
    # TODO: DRY this up with Root role
    class Targets
      def self.empty
        new('delegations' => {}, 'targets' => {})
      end

      def initialize(content)
        @target = content
        @root   = @target.fetch('delegations', {})
      end

      def sign_role(role, content, *keys)
        signed = keys.inject(Tuf::Signer.wrap(content)) do |content, key|
          Tuf::Signer.sign(content, key)
        end

        # Verify that this role contains sufficent public keys to unwrap what
        # was just signed.
        unwrap_role role, signed

        signed
      end

      def unwrap_role(role, content)
        # TODO: get threshold for role rather than requiring all signatures to
        # be valid.
        Tuf::Signer.unwrap(content, self)
      end

      def to_hash
        @target.merge(
          '_type' => 'Targets'
        )
      end

      def add_file(file)
        raise "File already exists." if @target['targets'][file.path]

        replace_file(file)
      end

      def replace_file(file)
        @target['targets'][file.path] = file.to_hash
      end

      def delegate_to(role_name, keys)
        @root['keys'] ||= {}
        keys.each do |key|
          @root['keys'][key.id] = key.to_hash
        end

        delegated_roles << {
          'name' => role_name,
          'keyids' => keys.map {|x| x.id }
        }
      end

      def files
        @target.fetch('targets')
      end

      def delegated_roles
        @root['roles'] ||= []
      end

      def fetch(key_id)
        key(key_id)
      end

      def path_for(role)
        "targets/#{role}"
      end

      def delegations
        @root['roles']
      end

      private

      attr_reader :root

      def key(key_id)
        keys = root.fetch('keys', {})

        Tuf::Key.new(keys.fetch(key_id))
      end
    end
  end
end
