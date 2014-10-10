class Linkset < ActiveRecord::Base
  belongs_to :rubygem

  LINKS = {
    'home' => 'homepage_uri',
    'code' => 'source_code_uri',
    'docs' => 'documentation_uri',
    'wiki' => 'wiki_uri',
    'mail' => 'mailing_list_uri',
    'bugs' => 'bug_tracker_uri'
  }.freeze

  LINKS.each do |url, aka|
    validates_formatting_of url.to_sym,
      using: :url,
      allow_nil: true,
      allow_blank: true,
      message: "does not appear to be a valid URL"

    alias_attribute aka.to_sym, url.to_sym
  end

  def empty?
    LINKS.keys.map { |link| attributes[link] }.all?(&:blank?)
  end

  def update_attributes_from_gem_specification!(spec)
    update_attributes!(home: spec.homepage)
  end
end
