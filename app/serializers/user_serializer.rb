class UserSerializer < ApplicationSerializer
  attributes :id, :handle
  attribute :email, unless: :email_hidden?

  delegate :email, to: :object

  def to_xml(options = {})
    super(options.merge(root: 'user'))
  end

  def email_hidden?
    object.hide_email
  end
end
