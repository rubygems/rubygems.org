# frozen_string_literal: true

class RubygemContents::Tree
  attr_reader :trees, :blobs

  def initialize(trees, blobs)
    @trees = trees
    @blobs = blobs
  end

  def empty?
    trees.blank? && blobs.blank?
  end
  alias blank? empty?

  def present?
    !empty?
  end

  def each_tree(&)
    trees.keys.each(&)
  end

  def each_blob(&)
    blobs.keys.each(&)
  end
end
