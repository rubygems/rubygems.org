require 'json'

module Tuf
  class Signer
    class << self
      # Return the wrapped document inside a new signing envelope that contains
      # all signatures from the previous one, plus a new signature from the
      # given key.
      #
      # TODO: handle signing with the same key twice.
      def sign(wrapped_document, key)
        unwrapped = wrapped_document.fetch('signed') {
          raise "The given document is not wrapped in a signing envelope"
        }

        to_sign = Tuf::Serialize.canonical(unwrapped)

        signed = wrapped_document.dup
        signed['signatures'] << {
          'keyid'  => key.id,
          'method' => key.type,
          'sig'    => key.sign(to_sign)
        }
        signed
      end

      # Wrap a document in an empty signing envelope. Multiple signatures can
      # be added to this envelope using the .sign method.
      #
      # TODO: Support `as_json` method to avoid calling `to_hash` everywhere.
      def wrap(to_sign)
        {
          'signatures' => [],
          'signed'     => to_sign,
        }
      end

      def sign_unwrapped(to_sign, key)
        sign(wrap(to_sign), key)
      end

      # Verify signatures on a document and return the signed portion.
      #
      # TODO: Support threshold parameter.
      def unwrap(signed_document, keystore)
        verify!(signed_document, keystore)
        unwrap_unsafe(signed_document)
      end

      # Unwrap a document without verifying signatures. This should only ever
      # be used internal to this class, or in a bootstrapping situation (such
      # as root.txt) where you are going to verify the document later.
      #
      # All external uses of this method MUST have explicit documentation
      # justifying that use.
      def unwrap_unsafe(signed_document)
        signed_document.fetch('signed') {
          raise "The given document is not wrapped in a signing envelope"
        }
      end

      private

      def verify!(signed_document, keystore)
        document = Tuf::Serialize.canonical(unwrap_unsafe(signed_document))

        signed_document.fetch('signatures').each do |sig|
          key_id = sig.fetch('keyid')
          method = sig.fetch('method')

          key = keystore.fetch(key_id)
          key.valid_digest?(document, sig.fetch('sig')) ||
            raise("Invalid signature for #{key_id}")
        end
      end
    end
  end
end
