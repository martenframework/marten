module Marten
  module CLI
    abstract class Generator
      class Model < Generator
        class FieldDefinition
          module QualifierRenderer
            @@registry = {} of ::String => Proc(String?, String) | Proc(String?, String?)

            def self.register(field_type : String, renderer : Proc(String?, String) | Proc(String?, String?))
              @@registry[field_type] = renderer
            end

            def self.registry
              @@registry
            end

            # :nodoc:
            RELATIONSHIP_RENDERER = ->(qualifier : String?) { "to: #{qualifier}" }

            register "many_to_one", RELATIONSHIP_RENDERER
            register "many_to_many", RELATIONSHIP_RENDERER
            register "one_to_one", RELATIONSHIP_RENDERER
            register "string", ->(qualifier : String?) { qualifier.nil? ? "max_size: 255" : "max_size: #{qualifier}" }
            register "text", ->(qualifier : String?) { qualifier.nil? ? nil : "max_size: #{qualifier}" }
          end
        end
      end
    end
  end
end
