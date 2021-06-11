module Marten
  module DB
    module Management
      module Constraint
        # Represents a unique constraint used when creating or altering tables.
        class Unique
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

          # Returns a copy of the unique constraint.
          def clone
            self.class.new(@name.dup, @column_names.clone)
          end

          # Returns a serialized version of the unique constraint arguments to be used when generating migrations.
          #
          # The returned string will be used in the context of `add_unique_constraint` / `unique_constraint` statements
          # in generated migrations.
          def serialize_args : ::String
            "#{name.inspect}, #{column_names.inspect}"
          end
        end
      end
    end
  end
end
