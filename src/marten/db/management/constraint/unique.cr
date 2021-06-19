require "../../concerns/can_format_strings_or_symbols"

module Marten
  module DB
    module Management
      module Constraint
        # Represents a unique constraint used when creating or altering tables.
        class Unique
          include CanFormatStringsOrSymbols

          @name : String
          @column_names : Array(String)

          # Returns the unique constraint name.
          getter name

          # Returns the column names that are part of the unique constraint.
          getter column_names

          def initialize(name : String | Symbol, column_names : Array(String | Symbol))
            @name = name.to_s
            @column_names = column_names.map(&.to_s)
          end

          # Returns true if the other unique constraint corresponds to the same unique constraint configuration.
          def ==(other : self)
            super || (name == other.name && column_names == other.column_names)
          end

          # Returns a copy of the unique constraint.
          def clone
            self.class.new(@name.dup, @column_names.clone)
          end

          # Returns a serialized version of the unique constraint arguments to be used when generating migrations.
          #
          # The returned string will be used in the context of `add_unique_constraint` / `unique_constraint` statements
          # in generated migrations.
          def serialize_args : ::String
            "#{format_string_or_symbol(name)}, [#{column_names.map { |n| format_string_or_symbol(n) }.join(", ")}]"
          end
        end
      end
    end
  end
end
