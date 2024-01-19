class Events::TableDetailsComponent < ApplicationComponent
  extend Dry::Initializer

  option :event
  delegate :additional, to: :event

  def template
    raise NotImplementedError
  end

  def self.translation_path
    super.gsub(/\.[^.]+\z/, "")
  end

  private

  def link_to_user_from_gid(gid, text)
    user =
      begin
        gid&.find(only: [User])
      rescue ActiveRecord::RecordNotFound # rubocop:disable Lint/SuppressedException
      end

    if user
      helpers.link_to text, profile_path(user.display_id), alt: user.display_handle, title: user.display_handle
    else
      text
    end
  end

  def link_to_version_from_gid(gid, number, platform)
    if (version = gid&.find)
      helpers.link_to version.to_title, rubygem_version_path(version.rubygem.slug, version.slug)
    else
      "#{rubygem.name} (#{number}#{platform.blank? || platform == 'ruby' ? '' : "-#{platform}"})"
    end
  end
end
