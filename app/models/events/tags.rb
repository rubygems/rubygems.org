module Events::Tags
  extend ActiveSupport::Concern

  def additional_type
    tags.fetch(tag, nil)
  end

  def additional
    additional_type&.new(super) || super
  end

  def additional=(value)
    super(value&.to_h)
  end

  included do
    validates :tag, presence: true, inclusion: { in: ->(_) { tags.keys } }
    validates :additional, nested: true, allow_nil: true
    belongs_to :ip_address, optional: true
    belongs_to :geoip_info, optional: true

    cattr_reader(:tags) { {} }
  end

  class_methods do
    def define_event(tag, &blk)
      raise ArgumentError, "Tag #{tag.inspect} already defined #{tags.inspect}" if tags.key?(tag)

      event = Class.new(ApplicationModel) do
        attribute :user_agent_info, Types::JsonDeserializable.new(Events::UserAgentInfo)

        class_eval(&blk) if blk
      end
      const_set(Events::Tag.additional_name(tag), event)
      tags[tag] = event

      -tag
    end
  end
end
