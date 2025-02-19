# frozen_string_literal: true

require_relative 'naming'
require_relative 'special_cases'

module InfernoSuiteGenerator
  class Generator
    class ReadTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir, suite_config)
          ig_metadata.groups
                     .reject { |group| SpecialCases.exclude_group? group }
                     .select { |group| read_interaction(group).present? }
                     .each { |group| new(group, base_output_dir, suite_config).generate }
        end

        def read_interaction(group_metadata)
          group_metadata.interactions.find { |interaction| interaction[:code] == 'read' }
        end
      end

      attr_accessor :group_metadata, :base_output_dir, :suite_config

      def initialize(group_metadata, base_output_dir, suite_config)
        self.group_metadata = group_metadata
        self.base_output_dir = base_output_dir
        self.suite_config = suite_config
      end

      def template
        @template ||= File.read(File.join(__dir__, '..', 'templates', 'read.rb.erb'))
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

      def read_interaction
        self.class.read_interaction(group_metadata)
      end

      def profile_identifier
        Naming.snake_case_for_profile(group_metadata)
      end

      def test_id
        "#{suite_config[:test_id_prefix]}_#{group_metadata.reformatted_version}_#{profile_identifier}_read_test"
      end

      def class_name
        "#{Naming.upper_camel_case_for_profile(group_metadata)}ReadTest"
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
        if group_metadata.delayed? && resource_type != 'Provenance'
          "scratch.dig(:references, '#{resource_type}')"
        else
          'all_scratch_resources'
        end
      end

      def conformance_expectation
        read_interaction[:expectation]
      end

      def needs_location_id?
        resource_type == 'Location'
      end

      def needs_organization_id?
        resource_type == 'Organization'
      end

      def needs_practitioner_id?
        resource_type == 'Practitioner'
      end

      def needs_practitioner_role_id?
        resource_type == 'PractitionerRole'
      end

      def generate
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
