# frozen_string_literal: true

require_relative 'naming'
require_relative 'special_cases'

module InfernoSuiteGenerator
  class Generator
    class SuiteGenerator
      class << self
        def generate(ig_metadata, base_output_dir, suite_config)
          new(ig_metadata, base_output_dir, suite_config).generate
        end
      end

      attr_accessor :ig_metadata, :base_output_dir, :suite_config

      def initialize(ig_metadata, base_output_dir, suite_config)
        self.ig_metadata = ig_metadata
        self.base_output_dir = base_output_dir
        self.suite_config = suite_config
      end

      def version_specific_message_filters
        []
      end

      def template
        @template ||= File.read(File.join(__dir__, '..', 'templates', 'suite.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def test_kit_module_name
        suite_config[:test_kit_module_name]
      end

      def base_output_file_name
        suite_config[:base_output_file_name]
      end

      def class_name
        suite_config[:test_suite_class_name]
      end

      def module_name
        "#{suite_config[:test_module_name]}#{ig_metadata.reformatted_version.upcase}"
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def suite_id
        "#{suite_config[:test_id_prefix]}_#{ig_metadata.reformatted_version}"
      end

      def fhir_api_group_id
        "#{suite_config[:test_id_prefix]}_#{ig_metadata.reformatted_version}_fhir_api"
      end

      def title
        "#{suite_config[:title]} #{ig_metadata.ig_version}"
      end

      def ig_identifier
        version = ig_metadata.ig_version[1..] # Remove leading 'v'
        "#{suite_config[:ig_identifier]}##{version}"
      end

      def ig_link
        case ig_metadata.ig_version
        when 'v0.3.0-ballot'
          'http://hl7.org.au/fhir/core/0.3.0-ballot'
        end
      end

      def generate
        File.open(output_file_name, 'w') { |f| f.write(output) }
      end

      def groups
        ig_metadata.ordered_groups.compact
                   .reject { |group| SpecialCases.exclude_group? group }
      end

      def group_id_list
        @group_id_list ||=
          groups.map(&:id)
      end

      def group_file_list
        @group_file_list ||=
          groups.map { |group| group.file_name.delete_suffix('.rb') }
      end

      def capability_statement_file_name
        # "../../custom_groups/#{ig_metadata.ig_version}/capability_statement_group"
        '../../custom_groups/v0.3.0-ballot/capability_statement_group'
      end

      def capability_statement_group_id
        # "au_core_#{ig_metadata.reformatted_version}_capability_statement"
        'au_core_v030_ballot_capability_statement'
      end
    end
  end
end
