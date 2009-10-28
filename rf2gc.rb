# rf2gc.rb -- defines the RF2GC module
#
# To use, run the file via runner or console, and
# add/give the command:
#
#   RF2GC.transfer_records
#
# transfer_records expects a file called rfdata.txt, containing lines 
# like this:
#
# dblack@blah.com|asofasoinaosdfiansdofiansdelgoid
#
# i.e., email address and 32-char MD5 password, separated by a pipe. 
#
# Given such a file, it will go line by line and:
#
#  * look for an existing Rubyforger or Gemcutter 
#    with that email, and skip if found
#  * create a new Rubyforger record
#  * create a new Gemcutter record with a random password
#  * back out of both creations if either fails
#
# It logs progressively to rf2gclog.txt.
#
# Comment lines (#-based) and blank lines are permitted in the
# input file. 

module RF2GC

  RFFILE    = "rfdata.txt"
  LOGFILE   = "rf2gclog.txt"

  EMAIL_RE  = /[^@|]+@[^@.|]+\.\w+/
  PW_RE     = /\w{32}/
  RECORD_RE = /\A#{EMAIL_RE}\|#{PW_RE}\Z/
  IGNORE_RE = /^\s*(#.*?)?\Z/

  def self.transfer_records
    @log = File.open(LOGFILE, "a")

    File.open(RFFILE) do |fh|
      fh.each_with_index do |record,i|

        next if ignore?(record)

        unless well_formed?(record)
          log("Bad record at line #{i}")
          next
        end

        show_progress(i)
    
        record.chomp!
        email, password = record.split('|')
    
        rfer = Rubyforger.find_by_email(email)
        gcer = User.find_by_email(email)
        next if either_exists?(rfer, gcer)

        rfer = Rubyforger.new(:email => email, :encrypted_password => password)
        unless rfer.save
          log("Couldn't save Rubyforger: #{rfer.email}")
          next
        end

        user = User.new(:email => email, :password => random_password,
                        :email_confirmed => true)
        unless user.save
          log("Couldn't save user: #{user.email}")
          Rubyforger.delete(rfer.id)
          next
        end
      end
    end
  end

  def self.well_formed?(record)
    record =~ RECORD_RE
  end

  def self.ignore?(record)
    record =~ IGNORE_RE
  end

  def self.log(msg)
    @log.puts Time.now.strftime("%c") + ": #{msg}"
  end

  def self.random_password
    (Time.now + rand(100000000)).to_s
  end

  def self.either_exists?(rfer, gcer)
    log("Rubyforger exists: #{rfer}") if rfer
    log("Gemcutter account exists: #{gcer}") if gcer
    return rfer || gcer
  end

  def self.show_progress(i)
    print "\r#{i}" if 1000 % (i+1) == 0
  end
end
