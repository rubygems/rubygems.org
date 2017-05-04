module AnnouncementsHelper
  ANNOUNCEMENT_READ_TOKEN = "hidden".freeze

  def announcement_visible?(announcement)
    announcement.present? && cookies[announcement.token] != ANNOUNCEMENT_READ_TOKEN
  end

  def current_announcement
    Announcement.last
  end
end
