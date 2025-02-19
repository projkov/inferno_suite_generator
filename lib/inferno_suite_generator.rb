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
require_relative 'inferno_suite_generator/search_test.rb'
require_relative "inferno_suite_generator/version"

module InfernoSuiteGenerator
  class Generator
    def self.generate(ig_folder, filepath_to_include, output_dir,
                      test_module_name, test_id_prefix, test_kit_module_name)
      ig_packages = Dir.glob(File.join(Dir.pwd, 'lib', ig_folder, 'igs', '*.tgz'))

      ig_packages.each do |ig_package|
        new(ig_package, filepath_to_include, output_dir,
            test_module_name, test_id_prefix, test_kit_module_name).generate
      end
    end

    attr_accessor :ig_resources, :ig_metadata, :ig_file_name, :filepath_to_include,
                  :output_dir, :test_module_name, :test_id_prefix, :test_kit_module_name

    def initialize(ig_file_name, filepath_to_include, output_dir,
                   test_module_name, test_id_prefix, test_kit_module_name)
      self.ig_file_name = ig_file_name
      self.filepath_to_include = filepath_to_include
      self.output_dir = output_dir
      self.test_module_name = test_module_name
      self.test_id_prefix = test_id_prefix
      self.test_kit_module_name = test_kit_module_name
    end

    def generate
      puts "Generating tests for IG #{File.basename(ig_file_name)}"
      load_ig_package
      extract_metadata
      generate_search_tests
      generate_read_tests
      generate_provenance_revinclude_search_tests
      generate_include_search_tests
      generate_validation_tests
      generate_must_support_tests
      generate_reference_resolution_tests
      generate_groups
      generate_suites
      use_tests
    end

    def extract_metadata
      self.ig_metadata = IGMetadataExtractor.new(ig_resources).extract

      FileUtils.mkdir_p(base_output_dir)
      File.open(File.join(base_output_dir, 'metadata.yml'), 'w') do |file|
        file.write(YAML.dump(ig_metadata.to_hash))
      end
    end

    def base_output_dir
      File.join(output_dir, 'generated', ig_metadata.ig_version)
    end

    def load_ig_package
      FHIR.logger = Logger.new('/dev/null')
      self.ig_resources = IGLoader.new(ig_file_name).load
    end

    def generate_reference_resolution_tests
      ReferenceResolutionTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_must_support_tests
      MustSupportTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_validation_tests
      ValidationTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_read_tests
      ReadTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_search_tests
      SearchTestGenerator.generate(ig_metadata, base_output_dir,
                                   test_module_name, test_id_prefix,
                                   test_kit_module_name)
      generate_multiple_or_search_tests
      generate_multiple_and_search_tests
      generate_chain_search_tests
      SpecialIdentifierSearchTestGenerator.generate(ig_metadata, base_output_dir,
                                   test_module_name, test_id_prefix,
                                   test_kit_module_name)
      generate_special_identifiers_chain_search_tests
    end

    def generate_include_search_tests
      IncludeSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_provenance_revinclude_search_tests
      ProvenanceRevincludeSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_multiple_or_search_tests
      MultipleOrSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_multiple_and_search_tests
      MultipleAndSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_chain_search_tests
      ChainSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_special_identifiers_chain_search_tests
      SpecialIdentifiersChainSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_groups
      GroupGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_suites
      SuiteGenerator.generate(ig_metadata, base_output_dir)
    end

    def use_tests
      file_content = File.read(filepath_to_include)
      string_to_add = "require_relative '#{base_output_dir.split('/lib/').last}/au_core_test_suite'"

      return if file_content.include? string_to_add

      file_content << "\n#{string_to_add}"
      File.write(filepath_to_include, file_content)
    end
  end
end
