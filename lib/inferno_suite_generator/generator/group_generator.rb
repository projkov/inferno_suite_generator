# frozen_string_literal: true

require_relative 'naming'
require_relative 'special_cases'
require_relative '../helpers'

module InfernoSuiteGenerator
  class Generator
    class GroupGenerator
      class << self
        def generate(ig_metadata, base_output_dir, suite_config)
          ig_metadata.ordered_groups
                     .compact
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
        @template ||= File.read(File.join(__dir__, '..', 'templates', 'group.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def base_metadata_file_name
        'metadata.yml'
      end

      def class_name
        "#{Naming.upper_camel_case_for_profile(group_metadata)}Group"
      end

      def module_name
        "#{suite_config[:test_module_name]}#{group_metadata.reformatted_version.upcase}"
      end

      def title
        group_metadata.title
      end

      def short_description
        group_metadata.short_description
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def metadata_file_name
        File.join(base_output_dir, profile_identifier, base_metadata_file_name)
      end

      def profile_identifier
        Naming.snake_case_for_profile(group_metadata)
      end

      def group_id
        "#{suite_config[:test_id_prefix]}_#{group_metadata.reformatted_version}_#{profile_identifier}"
      end

      def test_kit_module_name
        suite_config[:test_kit_module_name]
      end

      def resource_type
        group_metadata.resource
      end

      def search_validation_resource_type
        "#{resource_type} resources"
      end

      def profile_name
        group_metadata.profile_name
      end

      def profile_url
        group_metadata.profile_url
      end

      def optional?
        resource_type == 'QuestionnaireResponse'
      end

      def generate
        File.open(output_file_name, 'w') { |f| f.write(output) }
        group_metadata.id = group_id
        group_metadata.file_name = base_output_file_name
        File.open(metadata_file_name, 'w') { |f| f.write(YAML.dump(group_metadata.to_hash)) }
      end

      def test_id_list
        @test_id_list ||= group_metadata.tests.map { |test| test[:id] }
      end

      def test_file_list
        @test_file_list ||=
          group_metadata.tests.map do |test|
            name_without_suffix = test[:file_name].delete_suffix('.rb')
            name_without_suffix.start_with?('..') ? name_without_suffix : "#{profile_identifier}/#{name_without_suffix}"
          end
      end

      def required_searches
        group_metadata.searches.select { |search| search[:expectation] == 'SHALL' }
      end

      def search_param_name_string
        required_searches
          .map { |search| search[:names].join(' + ') }
          .map { |names| "* #{names}" }
          .join("\n")
      end

      def description
        Helpers.get_group_description_text(title, resource_type, profile_name, group_metadata.version, profile_url,
                                           required_searches, search_param_name_string, search_validation_resource_type, resource_type)
      end
    end
  end
end
