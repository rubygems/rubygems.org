class CreateGemNameReservations < ActiveRecord::Migration[7.0]
  ORIGINAL_GEM_NAME_RESERVED_LIST = %w[
    cgi-session
    complex
    continuation
    coverage
    enumerator
    expect
    fiber
    mkmf
    profiler
    pty
    rational
    rbconfig
    socket
    thread
    unicode_normalize
    ubygems
    update_with_your_gem_name_prior_to_release_to_rubygems_org
    update_with_your_gem_name_immediately_after_release_to_rubygems_org

    jruby
    mri
    mruby
    ruby
    rubygems
    gem
    update_rubygems
    install
    uninstall
    sidekiq-pro
    graphql-pro

    action-cable
    action_cable
    action-mailer
    action_mailer
    action-pack
    action_pack
    action-view
    action_view
    active-job
    active_job
    active-model
    active_model
    active-record
    active_record
    active-storage
    active_storage
    active-support
    active_support
    sprockets_rails
    rail-ties
    rail_ties
  ].freeze

  def change
    create_table :gem_name_reservations do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :gem_name_reservations, :name, unique: true

    reversible do |change|
      change.up do
        GemNameReservation.insert_all(ORIGINAL_GEM_NAME_RESERVED_LIST.map { |name| { name: name } })
      end
    end
  end
end
