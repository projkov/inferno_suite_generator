# frozen_string_literal: true

require_relative 'naming'
require_relative 'special_cases'

module InfernoSuiteGenerator
  class Generator
    class ReferenceResolutionTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir, suite_config)
          ig_metadata.groups
                     .reject { |group| SpecialCases.exclude_group? group }
                     .each { |group| new(group, base_output_dir, suite_config).generate }
        end
      end

      attr_accessor :group_metadata, :base_output_dir, :suite_config

      def initialize(group_metadata, base_output_dir, suite_config)
        self.group_metadata = group_metadata
        self.base_output_dir = base_output_dir
        self.suite_config = suite_config
      end

      def template
        @template ||= File.read(File.join(__dir__, '..', 'templates', 'reference_resolution.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def output_file_directory
        File.join(base_output_dir, profile_identifier)
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def profile_identifier
        Naming.snake_case_for_profile(group_metadata)
      end

      def test_id
        "#{suite_config[:test_id_prefix]}_#{group_metadata.reformatted_version}_#{profile_identifier}_reference_resolution_test"
      end

      def class_name
        "#{Naming.upper_camel_case_for_profile(group_metadata)}ReferenceResolutionTest"
      end

      def module_name
        "#{suite_config[:test_module_name]}#{group_metadata.reformatted_version.upcase}"
      end

      def test_kit_module_name
        suite_config[:test_kit_module_name]
      end

      def resource_type
        group_metadata.resource
      end

      def resource_collection_string
        'scratch_resources[:all]'
      end

      def must_support_references
        group_metadata.must_supports[:elements]
                      .select { |element| element[:types]&.include?('Reference') }
      end

      def must_support_reference_list_string
        must_support_references
          .map { |element| "#{' ' * 8}* #{resource_type}.#{element[:path]}" }
          .uniq
          .sort
          .join("\n")
      end

      def generate
        return if must_support_references.empty?

        FileUtils.mkdir_p(output_file_directory)
        File.open(output_file_name, 'w') { |f| f.write(output) }

        group_metadata.add_test(
          id: test_id,
          file_name: base_output_file_name
        )
      end
    end
  end
end
