# frozen_string_literal: true

module InfernoSuiteGenerator
  class Generator
    module Naming
      class << self
        def resources_with_multiple_profiles
          %w[Condition DiagnosticReport Observation]
        end

        def resource_has_multiple_profiles?(resource)
          resources_with_multiple_profiles.include? resource
        end

        def snake_case_for_profile(group_metadata)
          resource = group_metadata.resource
          return resource.underscore unless resource_has_multiple_profiles?(resource)

          group_metadata.name
                        .delete_prefix('au_core_')
                        .gsub('diagnosticreport', 'diagnostic_report')
                        .underscore
        end

        def upper_camel_case_for_profile(group_metadata)
          snake_case_for_profile(group_metadata).camelize
        end
      end
    end
  end
end
