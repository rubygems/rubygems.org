# see https://github.com/presidentbeef/brakeman/
desc 'Run Brakeman security scanner'
task :brakeman do
  previous_report = 'reports/old_brakeman.json'
  current_report  = 'reports/brakeman.json'
  if File.readable?(current_report)
    mv current_report, previous_report
    diff_reports = true
  else
    diff_reports = false
  end
  require 'brakeman'

  tracker = Brakeman.run app_path: '.', config_file: 'config/brakeman.yml'
  # https://github.com/presidentbeef/brakeman/blob/3.0_branch/lib/brakeman/report/report_table.rb#L42
  Brakeman.load_brakeman_dependency 'terminal-table'
  tracker.report.require_report 'base'
  custom_report = Class.new(Brakeman::Report::Base) do
    def initialize(tracker)
      super(tracker.instance_variable_get('@app_tree'), tracker)
    end

    def generate
      num_warnings = all_warnings.length

      Terminal::Table.new(headings: ['Scanned/Reported', 'Total']) do |t|
        t.add_row ['Controllers', tracker.controllers.length]
        t.add_row ['Models', tracker.models.length - 1]
        t.add_row ['Templates', number_of_templates(@tracker)]
        t.add_row ['Errors', tracker.errors.length]
        t.add_row ['Security Warnings', "#{num_warnings} (#{warnings_summary[:high_confidence]})"]
        t.add_row ['Ignored Warnings', ignored_warnings.length] unless ignored_warnings.empty?
      end
    end
  end
  report = custom_report.new(tracker)
  STDERR.puts "\033[31mBrakeman Report\033[0m"
  STDERR.puts report.generate
  # https://github.com/presidentbeef/brakeman/blob/3.0_branch/lib/brakeman.rb
  if diff_reports
    Brakeman.load_brakeman_dependency 'multi_json'
    require 'brakeman/report/initializers/multi_json'
    require 'brakeman/differ'
    previous_results = JSON.load(File.read(previous_report), symbolize_keys: true)[:warnings]
    new_results = JSON.load(tracker.report.to_json, symbolize_keys: true)[:warnings]
    STDERR.puts Brakeman::Differ.new(new_results, previous_results).diff
  end
  if report.all_warnings.any?
    STDERR.puts Terminal::Table.new(
      headings: %w(Summary Details),
      rows: [
        ["#{report.all_warnings.count} warnings.",
         "open 'reports/brakeman.html'"]
      ])
    exit Brakeman::Warnings_Found_Exit_Code if tracker.options[:exit_on_warn]
  end
end
