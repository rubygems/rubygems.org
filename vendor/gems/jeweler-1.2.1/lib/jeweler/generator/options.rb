class Jeweler
  class Generator
    class Options < Hash
      attr_reader :opts, :orig_args

      def initialize(args)
        super()

        @orig_args = args.clone
        self[:testing_framework]       = :shoulda
        self[:documentation_framework] = :rdoc

        @opts = OptionParser.new do |o|
          o.banner = "Usage: #{File.basename($0)} [options] reponame\ne.g. #{File.basename($0)} the-perfect-gem"

          o.on('--bacon', 'generate bacon specifications') do
            self[:testing_framework] = :bacon
          end

          o.on('--shoulda', 'generate shoulda tests') do
            self[:testing_framework] = :shoulda
          end

          o.on('--testunit', 'generate test/unit tests') do
            self[:testing_framework] = :testunit
          end

          o.on('--minitest', 'generate minitest tests') do
            self[:testing_framework] = :minitest
          end

          o.on('--rspec', 'generate rspec code examples') do
            self[:testing_framework] = :rspec
          end

          o.on('--micronaut', 'generate micronaut examples') do
            self[:testing_framework] = :micronaut
          end

          o.on('--cucumber', 'generate cucumber stories in addition to the other tests') do
            self[:use_cucumber] = true
          end

          o.on('--reek', 'generate rake task for reek') do
            self[:use_reek] = true
          end

          o.on('--roodi', 'generate rake task for roodi') do
            self[:use_roodi] = true
          end

          o.on('--create-repo', 'create the repository on GitHub') do
            self[:create_repo] = true
          end

          o.on('--gemcutter', 'setup project for gemcutter') do
            self[:gemcutter] = true
          end

          o.on('--rubyforge', 'setup project for rubyforge') do
            self[:rubyforge] = true
          end

          o.on('--summary [SUMMARY]', 'specify the summary of the project') do |summary|
            self[:summary] = summary
          end

          o.on('--description [DESCRIPTION]', 'specify a description of the project') do |description|
            self[:description] = description
          end

          o.on('--directory [DIRECTORY]', 'specify the directory to generate into') do |directory|
            self[:directory] = directory
          end

          o.on('--yard', 'use yard for documentation') do
            self[:documentation_framework] = :yard
          end

          o.on('--rdoc', 'use rdoc for documentation') do
            self[:documentation_framework] = :rdoc
          end

          o.on_tail('-h', '--help', 'display this help and exit') do
            self[:show_help] = true
          end
        end

        begin
          @opts.parse!(args)
        rescue OptionParser::InvalidOption => e
          self[:invalid_argument] = e.message
        end
      end

      def merge(other)
        self.class.new(@orig_args + other.orig_args)
      end

    end
  end
end
