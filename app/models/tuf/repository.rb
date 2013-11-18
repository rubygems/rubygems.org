require 'fileutils'

require 'tuf/role'
require 'tuf/signer'

module Tuf

  # A read-only view of a TUF repository.
  class Repository
    def initialize(opts)
      @bucket      = opts.fetch(:bucket)
      @signed_root = opts.fetch(:root)
      # TODO: Document, actually verify
      @root   = Tuf::Role::Root.new(Tuf::Signer.unwrap_unsafe(@signed_root))
    end

    def target(path)
      metadata = find_metadata path, 'targets', root

      if metadata
        file = Tuf::File.from_metadata(path, metadata)
        file.attach_body! bucket.get(path, cache_key: file.path_with_hash)
      end
    end

    def role(path)
      bucket.get('metadata/' + path + '.txt')
    end

    protected

    def release
      @release ||= begin
         file = timestamp.fetch_role('release', root)

         # TODO: Check expiry
         Role::Release.new(file, @bucket)
       end
    end

    def timestamp
      @timestamp ||= begin
        signed_file = JSON.parse(bucket.get("metadata/timestamp.txt", cache: false))

        # TODO: Check expiry
        Role::Timestamp.new(root.unwrap_role('timestamp', signed_file), @bucket)
      end
    end

    def find_metadata(path, role, parent)
      targets = Tuf::Role::Targets.new(release.fetch_role(role, parent))

      if targets.files[path]
        targets.files[path]
      else
        targets.delegated_roles.each do |role|
          x = find_metadata(path, role.fetch('name'), targets)
          return x if x
        end
        nil
      end
    end

    attr_reader :bucket, :root, :signed_root

  end
end
