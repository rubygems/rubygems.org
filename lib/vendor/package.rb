# -*- coding: utf-8 -*-
#--
# Copyright (C) 2004 Mauricio Julio Fernández Pradier
# See LICENSE.txt for additional licensing information.
#++

require 'rubygems/specification'

module GemPackage

  class Error < StandardError; end
  class NonSeekableIO < Error; end
  class ClosedIO < Error; end
  class BadCheckSum < Error; end
  class TooLongFileName < Error; end
  class FormatError < Error
    attr_reader :path

    def initialize message, path = nil
      @path = path

      message << " in #{path}" if path

      super message
    end

  end

  ##
  # Raised when a tar file is corrupt

  class TarInvalidError < Error; end

  # FIX: zenspider said: does it really take an IO?
  # passed to a method called open?!? that seems stupid.
  def self.open(io, mode = "r", signer = nil, &block)
    tar_type = case mode
               when 'r' then TarInput
               else
                 raise "Unknown Package open mode"
               end

    tar_type.open(io, signer, &block)
  end

  def self.pack(src, destname, signer = nil)
    TarOutput.open(destname, signer) do |outp|
      dir_class.chdir(src) do
        outp.metadata = (file_class.read("RPA/metadata") rescue nil)
        find_class.find('.') do |entry|
          case
          when file_class.file?(entry)
            entry.sub!(%r{\./}, "")
            next if entry =~ /\ARPA\//
            stat = File.stat(entry)
            outp.add_file_simple(entry, stat.mode, stat.size) do |os|
              file_class.open(entry, "rb") do |f|
                os.write(f.read(4096)) until f.eof?
              end
            end
          when file_class.dir?(entry)
            entry.sub!(%r{\./}, "")
            next if entry == "RPA"
            outp.mkdir(entry, file_class.stat(entry).mode)
          else
            raise "Don't know how to pack this yet!"
          end
        end
      end
    end
  end

end

require 'vendor/tar_input'
require 'vendor/tar_reader'

