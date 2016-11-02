class UserSerializer < ApplicationSerializer
  attributes :id, :email, :handle

  def email
    object.reload

    return nil if object.hide_email == true
    object.email
  end

  def to_xml(options = {})
    super(options.merge(root: 'user'))
  end
end
