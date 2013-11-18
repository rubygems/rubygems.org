require 'openssl'
require 'rubygems/tuf'

module Tuf

  # A grab bag of methods used to bootstrap TUF specifically for gemcutter.
  class Gemcutter
    def generate_key
      rsa = OpenSSL::PKey::RSA.new(2048, 65537)
      Tuf::Key.build('rsa', rsa.to_pem, rsa.public_key.to_pem)
    end

    def generate_root(online_keys, offline_keys)
      root = Tuf::Role::Root.empty
      root.add_roles(
        'root'      => offline_keys,
        'targets'   => offline_keys,
        'release'   => online_keys,
        'timestamp' => online_keys,
      )

      Tuf::Signer.wrap(root.to_hash)
    end

    def generate_targets(online_keys, offline_keys)
      targets = Tuf::Role::Targets.empty
      targets.delegate_to('targets/claimed', offline_keys)
      targets.delegate_to('targets/recently-claimed', online_keys)
      targets.delegate_to('targets/unclaimed', online_keys)

      Tuf::Signer.wrap(targets.to_hash)
    end

    def generate_claimed
      Tuf::Signer.wrap Tuf::Role::Targets.empty
    end

    def sign_file(key, path)
      signed = Tuf::Signer.sign(JSON.parse(File.read(path)), key)

      File.write path, Tuf::Serialize.canonical(signed)
    end

    def bootstrap!(bucket, online_key, signed_files)
      repo = Tuf::OnlineRepository.new(
        bucket:     bucket,
        online_key: online_key,
        root:       signed_files.fetch('root')
      )
      repo.bootstrap!

      unclaimed = Tuf::Role::Targets.empty
      recent    = Tuf::Role::Targets.empty

      signed_files['targets/recently-claimed'] = Tuf::Signer.sign_unwrapped(unclaimed.to_hash, online_key)
      signed_files['targets/unclaimed']        = Tuf::Signer.sign_unwrapped(recent.to_hash, online_key)

      repo.add_signed_delegated_role('targets', 'root', signed_files.fetch('targets'))
      repo.add_signed_delegated_role('targets/claimed', 'targets', signed_files.fetch('targets/claimed'))
      repo.add_signed_delegated_role('targets/recently-claimed', 'targets', signed_files.fetch('targets/recently-claimed'))
      repo.add_signed_delegated_role('targets/unclaimed', 'targets', signed_files.fetch('targets/unclaimed'))

      repo.publish!
    end
  end
end
