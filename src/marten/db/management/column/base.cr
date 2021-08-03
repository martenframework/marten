require "../../concerns/can_format_strings_or_symbols"

module Marten
  module DB
    module Management
      module Column
        # Abstract base migration column implementation.
        abstract class Base
          include CanFormatStringsOrSymbols

          getter default
          getter name

          setter name
          setter primary_key

          def initialize(
            @name : ::String,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = false,
            @default : ::DB::Any? = nil
          )
          end

          # Returns a copy of the column.
          abstract def clone

          # Returns the literal quoted value of the default value for a specific database connection.
          abstract def sql_quoted_default_value(connection : Connection::Base) : ::String?

          # Returns the raw type of the column to use for the column at hand and a specific database connection.
          abstract def sql_type(connection : Connection::Base) : ::String

          # Returns true if the other column corresponds to the same column configuration.
          def ==(other : self)
            super || (name == other.name && same_config?(other))
          end

          # Returns true if an index should be created at the database level for the column.
          def index?
            @index
          end

          # Returns a boolean indicating whether the column can be null or not.
          def null?
            @null
          end

          # Returns a boolean indicating whether the column is a primary key.
          def primary_key?
            @primary_key
          end

          # Returns true if the other column (which can have a different name) corresponds to the same configuration.
          def same_config?(other : Base)
            other.class == self.class &&
              primary_key? == other.primary_key? &&
              null? == other.null? &&
              unique? == other.unique? &&
              index? == other.index? &&
              default == other.default
          end

          # Returns a serialized version of the column arguments to be used when generating migrations.
          #
          # The returned string will be used in the context of `add_column` / `column` statements in generated
          # migrations.
          def serialize_args : ::String
            args = [%{#{format_string_or_symbol(name)}}, %{#{format_string_or_symbol(type)}}]
            args << %{primary_key: #{@primary_key}} if primary_key?
            args << %{null: #{@null}} if null?
            args << %{unique: #{@unique}} if unique?
            args << %{index: #{@index}} if index?
            args << %{default: #{default.inspect}} if !default.nil?
            args.join(", ")
          end

          # Returns the raw type suffix of the column to use for the column at hand and a specific database connection.
          def sql_type_suffix(connection : Connection::Base) : ::String?
            nil
          end

          # Returns the column type identifier.
          def type : ::String
            Column.registry.key_for(self.class)
          end

          # Returns a boolean indicating whether the column value should be unique throughout the associated table.
          def unique?
            @unique
          end

          # :nodoc:
          def contribute_to_project(project : ProjectState) : Nil
          end

          private def equivalent_to?(other)
            primary_key? == other.primary_key? &&
              null? == other.null? &&
              unique? == other.unique? &&
              index? == other.index? &&
              default == other.default
          end
        end
      end
    end
  end
end
