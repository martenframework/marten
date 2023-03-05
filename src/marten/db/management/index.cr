require "../concerns/can_format_strings_or_symbols"

module Marten
  module DB
    module Management
      # Represents an index used when creating or altering tables.
      class Index
        include CanFormatStringsOrSymbols

        @name : String
        @column_names : Array(String)

        # Returns the index name.
        getter name

        # Returns the column names that are part of the index.
        getter column_names

        # Returns a management index from an index definition.
        def self.from(index : DB::Index) : Index
          column_names = [] of String
          index.fields.each do |field|
            column = field.to_column

            if column.nil?
              raise Errors::InvalidField.new(
                "Field '#{field.id}' cannot be used as part of an index because it is not associated with " \
                "a database column"
              )
            end

            column_names << column.not_nil!.name
          end

          Management::Index.new(index.name, column_names)
        end

        def initialize(name : String | Symbol, column_names : Array(String | Symbol))
          @name = name.to_s
          @column_names = column_names.map(&.to_s)
        end

        # Returns true if the other index corresponds to the same index configuration.
        def ==(other : self)
          super || (name == other.name && column_names.to_set == other.column_names.to_set)
        end

        # Returns a copy of the index.
        def clone
          self.class.new(@name.dup, @column_names.clone)
        end

        # Returns a serialized version of the index arguments to be used when generating migrations.
        #
        # The returned string will be used in the context of `add_index` / `index` statements in generated migrations.
        def serialize_args : ::String
          "#{format_string_or_symbol(name)}, [#{column_names.map { |n| format_string_or_symbol(n) }.join(", ")}]"
        end
      end
    end
  end
end
