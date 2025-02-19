# frozen_string_literal: true

require 'fhir_models'
require 'inferno/ext/fhir_models'

require_relative 'inferno_suite_generator/generator/ig_loader'
require_relative 'inferno_suite_generator/generator/ig_metadata_extractor'
require_relative 'inferno_suite_generator/generator/group_generator'
require_relative 'inferno_suite_generator/generator/must_support_test_generator'
require_relative 'inferno_suite_generator/generator/provenance_revinclude_search_test_generator'
require_relative 'inferno_suite_generator/generator/read_test_generator'
require_relative 'inferno_suite_generator/generator/reference_resolution_test_generator'
require_relative 'inferno_suite_generator/generator/search_test_generator'
require_relative 'inferno_suite_generator/generator/suite_generator'
require_relative 'inferno_suite_generator/generator/validation_test_generator'
require_relative 'inferno_suite_generator/generator/multiple_or_search_test_generator'
require_relative 'inferno_suite_generator/generator/multiple_and_search_test_generator'
require_relative 'inferno_suite_generator/generator/chain_search_test_generator'
require_relative 'inferno_suite_generator/generator/special_identifier_search_test_generator'
require_relative 'inferno_suite_generator/generator/special_identifiers_chain_search_test_generator'
require_relative 'inferno_suite_generator/generator/include_search_test_generator'
require_relative 'inferno_suite_generator/search_test'
require_relative 'inferno_suite_generator/version'

module InfernoSuiteGenerator
  class Generator
    def self.generate(suite_config)
      ig_packages = Dir.glob(File.join(Dir.pwd, 'lib', suite_config[:gem_name], 'igs', '*.tgz'))

      ig_packages.each do |ig_package|
        new(ig_package, suite_config).generate
      end
    end

    attr_accessor :ig_resources, :ig_metadata, :ig_file_name, :suite_config

    def initialize(ig_file_name, suite_config)
      self.ig_file_name = ig_file_name
      self.suite_config = suite_config
    end

    def generate
      puts "Generating tests for IG #{File.basename(ig_file_name)}"
      load_ig_package
      extract_metadata
      generate_search_tests
      ReadTestGenerator.generate(ig_metadata, base_output_dir, suite_config)
      ProvenanceRevincludeSearchTestGenerator.generate(ig_metadata, base_output_dir, suite_config)
      IncludeSearchTestGenerator.generate(ig_metadata, base_output_dir, suite_config)
      ValidationTestGenerator.generate(ig_metadata, base_output_dir, suite_config)
      MustSupportTestGenerator.generate(ig_metadata, base_output_dir, suite_config)
      ReferenceResolutionTestGenerator.generate(ig_metadata, base_output_dir, suite_config)
      GroupGenerator.generate(ig_metadata, base_output_dir, suite_config)
      SuiteGenerator.generate(ig_metadata, base_output_dir, suite_config)
      use_tests
    end

    def extract_metadata
      self.ig_metadata = IGMetadataExtractor.new(ig_resources, suite_config).extract

      FileUtils.mkdir_p(base_output_dir)
      File.open(File.join(base_output_dir, 'metadata.yml'), 'w') do |file|
        file.write(YAML.dump(ig_metadata.to_hash))
      end
    end

    def base_output_dir
      File.join(suite_config[:output_path], 'generated', ig_metadata.ig_version)
    end

    def load_ig_package
      FHIR.logger = Logger.new('/dev/null')
      self.ig_resources = IGLoader.new(ig_file_name, suite_config).load
    end

    def generate_search_tests
      [
        SearchTestGenerator,
        MultipleOrSearchTestGenerator,
        MultipleAndSearchTestGenerator,
        ChainSearchTestGenerator,
        SpecialIdentifierSearchTestGenerator,
        SpecialIdentifiersChainSearchTestGenerator
      ].each { |generator| generator.generate(ig_metadata, base_output_dir, suite_config) }
    end

    def use_tests
      file_content = File.read(suite_config[:core_file_path])
      string_to_add = "require_relative '#{base_output_dir.split('/lib/').last}/au_core_test_suite'"

      return if file_content.include? string_to_add

      file_content << "\n#{string_to_add}"
      File.write(suite_config[:core_file_path], file_content)
    end
  end
end
