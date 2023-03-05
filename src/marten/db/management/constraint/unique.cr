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

          # Returns a management unique constraint from a unique constraint definition.
          def self.from(unique_constraint : DB::Constraint::Unique) : Unique
            column_names = [] of String
            unique_constraint.fields.each do |field|
              column = field.to_column

              if column.nil?
                raise Errors::InvalidField.new(
                  "Field '#{field.id}' cannot be used as part of a unique constraint because it is not associated " \
                  "with a database column"
                )
              end

              column_names << column.not_nil!.name
            end

            Management::Constraint::Unique.new(unique_constraint.name, column_names)
          end

          def initialize(name : String | Symbol, column_names : Array(String | Symbol))
            @name = name.to_s
            @column_names = column_names.map(&.to_s)
          end

          # Returns true if the other unique constraint corresponds to the same unique constraint configuration.
          def ==(other : self)
            super || (name == other.name && column_names.to_set == other.column_names.to_set)
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
