# Inferno Suite Generator (WIP)

## Usage example

``` ruby
namespace :au_core do
  desc 'Generate tests'
  task :generate do
    InfernoSuiteGenerator::Generator.generate(
      {
        title: 'AU Core',
        ig_identifier: 'hl7.fhir.au.core',
        gem_name: 'au_core_test_kit',
        core_file_path: './lib/au_core_test_kit.rb',
        output_path: './lib/au_core_test_kit/',
        test_module_name: 'AUCore',
        test_id_prefix: 'au_core',
        test_kit_module_name: 'AUCoreTestKit',
        test_suite_class_name: 'AUCoreTestSuite',
        base_output_file_name: 'au_core_test_suite.rb'
      }
    )
  end
end

```

