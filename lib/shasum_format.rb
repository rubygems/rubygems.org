# frozen_string_literal: true

# Generates and parses output matching the shasum/sha256sum command.
#
# Example of generated output:
#
#     f0bf715b0d47f077e4488870b86dc3649ed9a822  exe/rake
#     6371e1f14c5e64521d19d53c59ecca17f20fc67f  lib/rake.rb
#     576a4dbe718feb4c4837816cce4c5ce31c1633f6  lib/rake/application.rb
#
# Technically the output of shasum can be separated by " *" for binary.
# This doesn't support this format because we only parse what we generate.
#
# Command line examples:
#
# These commands produce the same file format as we generate:
# (substitute `sha256sum` for `shasum -a 256` if necessary):
#
# Create a file matching the output of shasum applied recursively.
# In the same directory as the root of the gem, run:
#
#     find * -type f -print0 | sort -z | xargs -0 shasum -a 256 > rake-13.0.6.sha256
#
# The output can be directly passed to shasum to check the files.
# In this example we fetch and unpack rack, then compare the checksums.
#
#     gem fetch rake -v 13.0.6
#     gem unpack rake-13.0.6.gem
#     cd rake-13.0.6
#     shasum -a 256 -c rake-13.0.6.sha256
#
module ShasumFormat
  class ParseError < RuntimeError; end

  # Splits a shasum file format into a Hash of path => checksum
  #
  # @param [String] body
  # @return [Hash] path => checksum
  def self.parse(body)
    body.to_s.each_line(chomp: true).to_h do |line|
      line.split("  ", 2).reverse
    end
  rescue StandardError => e
    raise ParseError, e.message
  end

  # Returns a file body matching the output of shasum command.
  #
  # @param [Hash] checksums path => checksum
  # @return [String] file body
  def self.generate(checksums)
    checksums.sort.filter_map do |path, checksum|
      next if path.blank? || checksum.blank?
      "#{checksum}  #{path}\n"
    end.join
  end
end
