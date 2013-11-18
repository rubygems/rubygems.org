require 'tuf/serialize'
require 'digest/sha2'

module Tuf

  # Value object for working with TUF key hashes.
  class Key

    # Convenience method for programatically building keys.
    def self.build(type, private, public)
      new Tuf::Serialize.roundtrip(
        'keytype' => type,
        'keyval' => {'private' => private, 'public' => public}
      )
    end

    def self.public(type, public)
      build(type, "", public)
    end

    def initialize(key)
      @key     = key
      @public  = key.fetch('keyval').fetch('public')
      @private = key.fetch('keyval').fetch('private')
      @type    = key.fetch('keytype')
      @id      = Digest::SHA256.hexdigest(Tuf::Serialize.canonical(to_hash))
    end

    # TODO: Unsupported for public key
    def sign(content)
      case type
      when 'insecure'
        Digest::MD5.hexdigest(public + content)
      when 'rsa'
        rsa_key = OpenSSL::PKey::RSA.new(private)
        rsa_key.sign(Gem::TUF::DIGEST_ALGORITHM.new, content).unpack("H*")[0]
      else raise "Unknown key type: #{type}"
      end
    end

    def valid_digest?(content, expected_digest)
      case type
      when 'insecure'
        expected_digest == Digest::MD5.hexdigest(public + content)
      when 'rsa'
        signature_bytes = [expected_digest].pack("H*")
        rsa_key = OpenSSL::PKey::RSA.new(public)
        rsa_key.verify(Gem::TUF::DIGEST_ALGORITHM.new, signature_bytes, content)
      else raise "Unknown key type: #{type}"
      end
    end

    def to_hash
      {
        'keytype' => type,
        'keyval' => {
          'private' => '', # Never include private key when writing out
          'public' => public,
        }
      }
    end

    attr_reader :id, :public, :private, :type
  end
end
