# -*- coding: utf-8 -*-
#--
# Copyright (C) 2004 Mauricio Julio Fernández Pradier
# See LICENSE.txt for additional licensing information.
#++

##
# TarReader reads tar files and allows iteration over their items

class GemPackage::TarReader

  ##
  # Raised if the tar IO is not seekable

  class UnexpectedEOF < StandardError; end

  ##
  # Creates a new TarReader on +io+ and yields it to the block, if given.

  def self.new(io)
    reader = super

    return reader unless block_given?

    begin
      yield reader
    ensure
      reader.close
    end

    nil
  end

  ##
  # Creates a new tar file reader on +io+ which needs to respond to #pos,
  # #eof?, #read, #getc and #pos=

  def initialize(io)
    @io = io
    @init_pos = io.pos
  end

  ##
  # Close the tar file

  def close
  end

  ##
  # Iterates over files in the tarball yielding each entry

  def each
    loop do
      return if @io.eof?

      header = GemPackage::TarHeader.from @io
      return if header.empty?

      entry = GemPackage::TarReader::Entry.new header, @io
      size = entry.header.size

      yield entry

      skip = (512 - (size % 512)) % 512
      pending = size - entry.bytes_read

      begin
        # avoid reading...
        @io.seek pending, IO::SEEK_CUR
        pending = 0
      rescue Errno::EINVAL, NameError
        while pending > 0 do
          bytes_read = @io.read([pending, 4096].min).size
          raise UnexpectedEOF if @io.eof?
          pending -= bytes_read
        end
      end

      @io.read skip # discard trailing zeros

      # make sure nobody can use #read, #getc or #rewind anymore
      entry.close
    end
  end

  alias each_entry each

  ##
  # NOTE: Do not call #rewind during #each

  def rewind
    if @init_pos == 0 then
      raise "unseekable io" unless @io.respond_to? :rewind
      @io.rewind
    else
      raise "unseekable io" unless @io.respond_to? :pos=
      @io.pos = @init_pos
    end
  end

end

# -*- coding: utf-8 -*-
#--
# Copyright (C) 2004 Mauricio Julio Fernández Pradier
# See LICENSE.txt for additional licensing information.
#++

##
#--
# struct tarfile_entry_posix {
#   char name[100];     # ASCII + (Z unless filled)
#   char mode[8];       # 0 padded, octal, null
#   char uid[8];        # ditto
#   char gid[8];        # ditto
#   char size[12];      # 0 padded, octal, null
#   char mtime[12];     # 0 padded, octal, null
#   char checksum[8];   # 0 padded, octal, null, space
#   char typeflag[1];   # file: "0"  dir: "5"
#   char linkname[100]; # ASCII + (Z unless filled)
#   char magic[6];      # "ustar\0"
#   char version[2];    # "00"
#   char uname[32];     # ASCIIZ
#   char gname[32];     # ASCIIZ
#   char devmajor[8];   # 0 padded, octal, null
#   char devminor[8];   # o padded, octal, null
#   char prefix[155];   # ASCII + (Z unless filled)
# };
#++
# A header for a tar file

class GemPackage::TarHeader

  ##
  # Fields in the tar header

  FIELDS = [
    :checksum,
    :devmajor,
    :devminor,
    :gid,
    :gname,
    :linkname,
    :magic,
    :mode,
    :mtime,
    :name,
    :prefix,
    :size,
    :typeflag,
    :uid,
    :uname,
    :version,
  ]

  ##
  # Pack format for a tar header

  PACK_FORMAT = 'a100' + # name
                'a8'   + # mode
                'a8'   + # uid
                'a8'   + # gid
                'a12'  + # size
                'a12'  + # mtime
                'a7a'  + # chksum
                'a'    + # typeflag
                'a100' + # linkname
                'a6'   + # magic
                'a2'   + # version
                'a32'  + # uname
                'a32'  + # gname
                'a8'   + # devmajor
                'a8'   + # devminor
                'a155'   # prefix

  ##
  # Unpack format for a tar header

  UNPACK_FORMAT = 'A100' + # name
                  'A8'   + # mode
                  'A8'   + # uid
                  'A8'   + # gid
                  'A12'  + # size
                  'A12'  + # mtime
                  'A8'   + # checksum
                  'A'    + # typeflag
                  'A100' + # linkname
                  'A6'   + # magic
                  'A2'   + # version
                  'A32'  + # uname
                  'A32'  + # gname
                  'A8'   + # devmajor
                  'A8'   + # devminor
                  'A155'   # prefix

  attr_reader(*FIELDS)

  ##
  # Creates a tar header from IO +stream+

  def self.from(stream)
    header = stream.read 512
    empty = (header == "\0" * 512)

    fields = header.unpack UNPACK_FORMAT

    name     = fields.shift
    mode     = fields.shift.oct
    uid      = fields.shift.oct
    gid      = fields.shift.oct
    size     = fields.shift.oct
    mtime    = fields.shift.oct
    checksum = fields.shift.oct
    typeflag = fields.shift
    linkname = fields.shift
    magic    = fields.shift
    version  = fields.shift.oct
    uname    = fields.shift
    gname    = fields.shift
    devmajor = fields.shift.oct
    devminor = fields.shift.oct
    prefix   = fields.shift

    new :name     => name,
        :mode     => mode,
        :uid      => uid,
        :gid      => gid,
        :size     => size,
        :mtime    => mtime,
        :checksum => checksum,
        :typeflag => typeflag,
        :linkname => linkname,
        :magic    => magic,
        :version  => version,
        :uname    => uname,
        :gname    => gname,
        :devmajor => devmajor,
        :devminor => devminor,
        :prefix   => prefix,

        :empty    => empty

    # HACK unfactor for Rubinius
    #new :name     => fields.shift,
    #    :mode     => fields.shift.oct,
    #    :uid      => fields.shift.oct,
    #    :gid      => fields.shift.oct,
    #    :size     => fields.shift.oct,
    #    :mtime    => fields.shift.oct,
    #    :checksum => fields.shift.oct,
    #    :typeflag => fields.shift,
    #    :linkname => fields.shift,
    #    :magic    => fields.shift,
    #    :version  => fields.shift.oct,
    #    :uname    => fields.shift,
    #    :gname    => fields.shift,
    #    :devmajor => fields.shift.oct,
    #    :devminor => fields.shift.oct,
    #    :prefix   => fields.shift,

    #    :empty => empty
  end

  ##
  # Creates a new TarHeader using +vals+

  def initialize(vals)
    unless vals[:name] && vals[:size] && vals[:prefix] && vals[:mode] then
      raise ArgumentError, ":name, :size, :prefix and :mode required"
    end

    vals[:uid] ||= 0
    vals[:gid] ||= 0
    vals[:mtime] ||= 0
    vals[:checksum] ||= ""
    vals[:typeflag] ||= "0"
    vals[:magic] ||= "ustar"
    vals[:version] ||= "00"
    vals[:uname] ||= "wheel"
    vals[:gname] ||= "wheel"
    vals[:devmajor] ||= 0
    vals[:devminor] ||= 0

    FIELDS.each do |name|
      instance_variable_set "@#{name}", vals[name]
    end

    @empty = vals[:empty]
  end

  ##
  # Is the tar entry empty?

  def empty?
    @empty
  end

  def ==(other) # :nodoc:
    self.class === other and
    @checksum == other.checksum and
    @devmajor == other.devmajor and
    @devminor == other.devminor and
    @gid      == other.gid      and
    @gname    == other.gname    and
    @linkname == other.linkname and
    @magic    == other.magic    and
    @mode     == other.mode     and
    @mtime    == other.mtime    and
    @name     == other.name     and
    @prefix   == other.prefix   and
    @size     == other.size     and
    @typeflag == other.typeflag and
    @uid      == other.uid      and
    @uname    == other.uname    and
    @version  == other.version
  end

  def to_s # :nodoc:
    update_checksum
    header
  end

  ##
  # Updates the TarHeader's checksum

  def update_checksum
    header = header " " * 8
    @checksum = oct calculate_checksum(header), 6
  end

  private

  def calculate_checksum(header)
    header.unpack("C*").inject { |a, b| a + b }
  end

  def header(checksum = @checksum)
    header = [
      name,
      oct(mode, 7),
      oct(uid, 7),
      oct(gid, 7),
      oct(size, 11),
      oct(mtime, 11),
      checksum,
      " ",
      typeflag,
      linkname,
      magic,
      oct(version, 2),
      uname,
      gname,
      oct(devmajor, 7),
      oct(devminor, 7),
      prefix
    ]

    header = header.pack PACK_FORMAT

    header << ("\0" * ((512 - header.size) % 512))
  end

  def oct(num, len)
    "%0#{len}o" % num
  end

end

# -*- coding: utf-8 -*-
#++
# Copyright (C) 2004 Mauricio Julio Fernández Pradier
# See LICENSE.txt for additional licensing information.
#--

##
# Class for reading entries out of a tar file

class GemPackage::TarReader::Entry

  ##
  # Header for this tar entry

  attr_reader :header

  ##
  # Creates a new tar entry for +header+ that will be read from +io+

  def initialize(header, io)
    @closed = false
    @header = header
    @io = io
    @orig_pos = @io.pos
    @read = 0
  end

  def check_closed # :nodoc:
    raise IOError, "closed #{self.class}" if closed?
  end

  ##
  # Number of bytes read out of the tar entry

  def bytes_read
    @read
  end

  ##
  # Closes the tar entry

  def close
    @closed = true
  end

  ##
  # Is the tar entry closed?

  def closed?
    @closed
  end

  ##
  # Are we at the end of the tar entry?

  def eof?
    check_closed

    @read >= @header.size
  end

  ##
  # Full name of the tar entry

  def full_name
    if @header.prefix != "" then
      File.join @header.prefix, @header.name
    else
      @header.name
    end
  rescue ArgumentError => e
    raise unless e.message == 'string contains null byte'
    raise Gem::Package::TarInvalidError,
          'tar is corrupt, name contains null byte'
  end

  ##
  # Read one byte from the tar entry

  def getc
    check_closed

    return nil if @read >= @header.size

    ret = @io.getc
    @read += 1 if ret

    ret
  end

  ##
  # Is this tar entry a directory?

  def directory?
    @header.typeflag == "5"
  end

  ##
  # Is this tar entry a file?

  def file?
    @header.typeflag == "0"
  end

  ##
  # The position in the tar entry

  def pos
    check_closed

    bytes_read
  end

  ##
  # Reads +len+ bytes from the tar file entry, or the rest of the entry if
  # nil

  def read(len = nil)
    check_closed

    return nil if @read >= @header.size

    len ||= @header.size - @read
    max_read = [len, @header.size - @read].min

    ret = @io.read max_read
    @read += ret.size

    ret
  end

  ##
  # Rewinds to the beginning of the tar file entry

  def rewind
    check_closed

    raise Gem::Package::NonSeekableIO unless @io.respond_to? :pos=

    @io.pos = @orig_pos
    @read = 0
  end

end
