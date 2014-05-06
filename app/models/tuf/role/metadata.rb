require 'json'

require 'tuf/file'

module Tuf
  module Role
    class NullBucket
      def get(*_); raise "Remote operations not available" end
      def create(*_); raise "Remote operations not available" end
    end

    class Metadata
      def self.empty(bucket = NullBucket.new)
        new({'meta' => {}}, bucket)
      end

      def initialize(source, bucket)
        @role_metadata = source['meta']
        @bucket = bucket
      end

      def fetch_role(role, parent)
        path = "metadata/" + role + ".txt"

        metadata = role_metadata.fetch(path) {
          raise "Could not find #{path} in: #{role_metadata.keys.sort.join("\n")}"
        }

        filespec = ::Tuf::File.from_metadata(path, role_metadata[path])

        data = bucket.get(filespec.path_with_hash)

        signed_file = filespec.attach_body!(data)

        parent.unwrap_role(role, JSON.parse(signed_file.body))
      end

      def replace(file)
        role_metadata[file.path] = file.to_hash
      end

      attr_reader :role_metadata, :bucket
    end

    class Timestamp < Metadata
      def to_hash
        {
          '_type'   => "Timestamp",
          'meta'    => role_metadata,
          'version' => 2
        }
      end
    end

    class Release < Metadata
      # TODO: Expires
      def to_hash
        {
          '_type'   => "Release",
          'meta'    => role_metadata,
          'version' => 2
        }
      end
    end
  end
end
