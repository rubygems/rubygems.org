class Download < DownloadRecord
  def query = { rubygem_id:, version_id:, log_ticket_id:, occurred_at: occurred_at.iso8601 }
  def id = query.values.join("_")

  belongs_to :rubygem, validate: false, optional: true
  belongs_to :version, validate: false, optional: true
  belongs_to :log_ticket, validate: false, optional: true

  validates :occurred_at, presence: true
  validates :downloads, presence: true

  def self.suffix = nil
  def self.time_period = nil

  def self.class_name_for(suffix:, time_period:)
    raise ArgumentError if suffix && !time_period
    [time_period.iso8601, suffix].compact.join("_").classify
  end

  [15.minutes, 1.day, 1.month, 1.year].each do |time_period|
    (%w[all_versions all_gems] << nil).each do |suffix|
      table_name = "#{Download.table_name}_#{time_period.inspect.parameterize(separator: '_')}#{"_#{suffix}" if suffix}"
      ::Download.class_eval(<<~RUBY, __FILE__, __LINE__ + 1) # rubocop:disable Style/DocumentDynamicEvalDefinition
        class #{class_name_for(suffix:, time_period:)} < Download
          attribute :downloads, :integer

          def readonly?
            true
          end

          def self.table_name = #{table_name.dump}

          def self.suffix = #{suffix&.dump || :nil}

          def self.time_period = #{time_period.inspect.parameterize(separator: '_').dump}
        end
      RUBY
    end
  end
end
