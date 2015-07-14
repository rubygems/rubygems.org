Rails.configuration.contacts = contacts = ActiveSupport::OrderedOptions.new

SecurityContact = Struct.new(:name, :key_id, :full_fingerprint, :email)
SecurityContacts = Struct.new(:contacts, :list_url) do
  include Enumerable
  attr_reader :names
  def initialize(*)
    super
    @names = contacts.map(&:name).join(", ")
  end
  def each(&block)
    contacts.each(&block)
  end
end
contacts.security = SecurityContacts.new([
  SecurityContact.new("Larry", "41C6E930", "0145 FD2B 52E8 0A8E 329A 16C7 AC68 AC04 41C6 E930", "richard@python.org"),
  SecurityContact.new("Moe", "41C6E930", "0145 FD2B 52E8 0A8E 329A 16C7 AC68 AC04 41C6 E930", "richard@python.org"),
  SecurityContact.new("Curly", "41C6E930", "0145 FD2B 52E8 0A8E 329A 16C7 AC68 AC04 41C6 E930", "richard@python.org"),

], "http://mail.python.org/mailman/listinfo/pydotorg-www").freeze
