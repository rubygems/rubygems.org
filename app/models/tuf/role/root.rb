require 'tuf/key'
require 'tuf/signer'

module Tuf
  module Role
    # TODO: DRY this up with Targets role
    class Root
      def self.empty
        new({ 'keys' => {}, 'roles' => {}})
      end

      def initialize(content)
        @root = content
      end

      def body
        @root
      end

      def unwrap_role(role, content)
        # TODO: get threshold for role rather than requiring all signatures to be
        # valid.
        Tuf::Signer.unwrap(content, self)
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

      def add_roles(roles)
        roles.each do |name, keys|
          keys.each do |key|
            @root['keys'][key.id] ||= key.to_hash
          end

          @root['roles'][name] = { 'keyids' => keys.map {|x| x.id }}
        end
      end

      def to_hash
        @root.merge('_type' => 'Root')
      end

      def files
        @target.fetch('targets')
      end

      def delegated_roles
        @root.fetch('roles', [])
      end

      def fetch(key_id)
        key(key_id)
      end

      def path_for(role)
        role
      end

      def delegations
        @root['roles']
      end

      private

      attr_reader :root

      def key(key_id)
        keys = root.fetch('keys', {})

        Tuf::Key.new(keys.fetch(key_id) {
          raise "#{key_id} not found among:\n#{keys.keys.join("\n")}"
        })
      end
    end
  end
end
