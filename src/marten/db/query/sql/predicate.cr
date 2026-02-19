require "./predicate/**"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          @@registry = {} of String => Base.class

          TIME_PART_PREDICATE_TYPES       = %w(year month day hour minute second)
          TIME_PART_COMPARISON_PREDICATES = %w(exact gt gte lt lte in isnull)

          def self.register(predicate_klass : Base.class)
            @@registry[predicate_klass.predicate_name] = predicate_klass
          end

          def self.registry
            @@registry
          end

          def self.time_part_comparison_predicate?(name : String) : Bool
            TIME_PART_COMPARISON_PREDICATES.includes?(name)
          end

          def self.time_part_predicate?(name : String) : Bool
            TIME_PART_PREDICATE_TYPES.includes?(name)
          end

          register Contains
          register Day
          register EndsWith
          register Exact
          register GreaterThan
          register GreaterThanOrEqual
          register Hour
          register IContains
          register IEndsWith
          register IExact
          register In
          register IsNull
          register IStartsWith
          register LessThan
          register LessThanOrEqual
          register Minute
          register Month
          register Second
          register StartsWith
          register Year
        end
      end
    end
  end
end
