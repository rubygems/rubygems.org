class Jeweler
  class Generator
    module MinitestMixin
      def self.extended(generator)
        generator.development_dependencies << "minitest"
      end

      def default_task
        'test'
      end

      def feature_support_require
        'mini/test'
      end

      def feature_support_extend
        'Mini::Test::Assertions'
      end

      def test_dir
        'test'
      end

      def test_task
        'test'
      end

      def test_pattern
        'test/**/*_test.rb'
      end

      def test_filename
        "#{require_name}_test.rb"
      end

      def test_helper_filename
        "test_helper.rb"
      end

    end
  end
end
