require "./annotation/**"

module Marten
  module DB
    module Query
      module SQL
        module Annotation
          @@registry = {} of String => Base.class

          def self.register(annotation_klass : Base.class)
            @@registry[annotation_klass.name.split("::").last.underscore] = annotation_klass
          end

          def self.registry
            @@registry
          end

          register Average
          register Count
          register Maximum
          register Minimum
          register Sum
        end
      end
    end
  end
end
