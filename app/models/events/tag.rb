class Events::Tag < ApplicationModel
  attribute :source_type, :string
  attribute :subject_type, :string
  attribute :action, :string

  def initialize(value)
    values = value.split(":")

    source_type = values[0]
    subject_type = values[1...-1]&.join(":").presence || source_type
    action = values[-1]

    super(source_type:, subject_type:, action:)
  end

  def to_a = [source_type, subject_type, action]
  def to_s = to_a.uniq.join(":")

  delegate :as_json, to: :to_s

  def self.to_struct(&blk)
    Class.new(ApplicationModel) do
      attribute :user_agent_info, Types::JsonDeserializable.new(Events::UserAgentInfo)

      class_eval(&blk) if blk
    end
  end

  class Type < ActiveRecord::Type::Text
    def cast(value)
      case value
      when NilClass, Events::Tag
        value
      when String
        Events::Tag.new(value)
      when Hash
        Events::Tag.new("").tap do |tag|
          tag.assign_attributes(value)
        end
      end
    end

    def serialize(value) = cast(value)&.to_s
  end
end
