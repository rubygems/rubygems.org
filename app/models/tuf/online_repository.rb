require 'tuf/repository'

module Tuf

  # An online repository has access to the online private key, enabling it to
  # make changes to the repository.
  class OnlineRepository < Repository
    def initialize(opts)
      super

      @online_key  = opts.fetch(:online_key)
    end

    # TODO: Handle heirachical delegations properly
    # TODO: parent_role is redundant
    # TODO: Document, DRY up with replace_file
    def add_file(file, role_name, parent_role)
      content = release.fetch_role(parent_role, root)
      parent = Tuf::Role.from_hash(content)

      targets = Tuf::Role::Targets.new(release.fetch_role(role_name, parent))
      targets.add_file(file)

      bucket.create(file.path, file.body)
      targets_signed = parent.sign_role(role_name, targets.to_hash, online_key)

      add_signed_delegated_role(role_name, parent_role, targets_signed)
    end

    # TODO: Handle heirachical delegations properly
    def replace_file(file, role_name, parent_role)
      content = release.fetch_role(parent_role, root)
      parent = Tuf::Role.from_hash(content)

      targets = Tuf::Role::Targets.new(release.fetch_role(role_name, parent))
      targets.replace_file(file)

      bucket.create(file.path, file.body)
      targets_signed = parent.sign_role(role_name, targets.to_hash, online_key)

      add_signed_delegated_role(role_name, parent_role, targets_signed)
    end

    # Creates and publishes an initial empty snapshot from nothing. Should only
    # be used during new system setup or disaster recovery.
    def bootstrap!
      root_file = Tuf::File.new 'metadata/root.txt',
        Tuf::Serialize.canonical(signed_root)

      targets = Tuf::Role::Targets.empty
      targets_file = build_role 'targets', targets

      release = Role::Release.empty
      release.replace(targets_file)
      release.replace(root_file)
      release_file = build_role 'release', release

      timestamp = Role::Timestamp.empty
      timestamp.replace(release_file)
      timestamp_file = build_role 'timestamp', timestamp

      [root_file, targets_file, release_file].each do |file|
        bucket.create file.path_with_hash, file.body
      end
      bucket.create timestamp_file.path, timestamp_file.body
    end

    # TODO: Document
    def add_signed_delegated_role(role, parent_role, signed_document)
      content = release.fetch_role(parent_role, root)
      parent  = Tuf::Role.from_hash(content)

      # Verify that the parent has sufficient keys to unwrap the document. If
      # not, this will raise - the caller needs to write an updated parent
      # first.
      parent.unwrap_role(role, signed_document)

      path = 'metadata/' + role + '.txt'

      file = Tuf::File.from_body(path, Tuf::Serialize.canonical(signed_document))
      release.replace(file)
      bucket.create(file.path_with_hash, file.body)
    end

    # Publishes a new consistent snapshot. The only file that is overwritten is
    # the timestamp, since that is the "root" of the metadata and needs to be
    # able to be fetched independent of others. All other files are persisted
    # with their hash added to their filename.
    def publish!
      release_file = build_role 'release', release

      timestamp.replace(release_file)

      timestamp_file = build_role 'timestamp', timestamp

      bucket.create(release_file.path_with_hash, release_file.body)
      bucket.create(timestamp_file.path, timestamp_file.body)
    end

    private

    attr_accessor :online_key

    def build_role(role, object)
      release_file = Tuf::File.new 'metadata/' + role + '.txt',
        Tuf::Serialize.canonical(root.sign_role(role, object.to_hash, online_key))
    end

  end
end
