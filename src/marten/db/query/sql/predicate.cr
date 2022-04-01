require "./predicate/**"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          @@registry = {} of String => Base.class

          def self.register(predicate_klass : Base.class)
            @@registry[predicate_klass.predicate_name] = predicate_klass
          end

          def self.registry
            @@registry
          end

          register Contains
          register EndsWith
          register Exact
          register GreaterThan
          register GreaterThanOrEqual
          register IContains
          register IEndsWith
          register IExact
          register In
          register IsNull
          register IStartsWith
          register LessThan
          register LessThanOrEqual
          register StartsWith
        end
      end
    end
  end
end
