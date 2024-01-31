module Events::Tags
  extend ActiveSupport::Concern

  included do
    validates :tag, presence: true, inclusion: { in: ->(_) { tags.keys } }
    attribute :tag, Events::Tag::Type.new
    validates :additional, nested: true, allow_nil: true
    belongs_to :ip_address, optional: true
    belongs_to :geoip_info, optional: true

    cattr_reader(:tags) { {} }

    def additional_type
      tags.fetch(tag, nil)
    end

    def additional
      additional_type&.new(super) || super
    end

    def additional=(value)
      super(value&.to_h)
    end
  end

  class_methods do
    def define_event(string, &blk)
      tag = Events::Tag.new(string).freeze
      raise ArgumentError, "Tag #{tag.inspect} already defined" if tags.key?(tag)
      event = Events::Tag.to_struct(&blk)
      tags[tag] = event

      const_name = [tag.subject_type == tag.source_type ? nil : tag.subject_type, tag.action].compact.join("_").upcase
      const_set(:"#{const_name.downcase.classify}Additional", event)

      tag
    end
  end
end
