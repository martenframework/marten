require "./predicate/**"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          @@registry = {} of String => Base.class
          @@transform_registry = {} of String => TransformBase.class

          def self.register(predicate_klass : Base.class)
            @@registry[predicate_klass.predicate_name] = predicate_klass
          end

          def self.registry
            @@registry
          end

          def self.register_transform(predicate_klass : TransformBase.class)
            @@transform_registry[predicate_klass.predicate_name] = predicate_klass
          end

          def self.transform_registry
            @@transform_registry
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

          register_transform Year
          register_transform Month
          register_transform Day
          register_transform Hour
          register_transform Minute
          register_transform Second
        end
      end
    end
  end
end
