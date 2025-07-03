class FlipperActor
  attr_reader :flipper_id, :record

  def initialize(record)
    @record = record
    @flipper_id = record.flipper_id
  end

  def to_s
    "#{record.handle} (#{record.class.name})"
  end

  def self.find(flipper_id)
    klass, handle = flipper_id.split(';')

    actor = case klass
            when "User"
              User.find_by(handle: handle)
            when "Organization"
              Organization.find_by(handle: handle)
            end

    actor && new(actor)
  end
end
