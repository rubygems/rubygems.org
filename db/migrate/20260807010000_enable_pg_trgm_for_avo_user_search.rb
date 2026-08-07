# frozen_string_literal: true

class EnablePgTrgmForAvoUserSearch < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"
  end
end
