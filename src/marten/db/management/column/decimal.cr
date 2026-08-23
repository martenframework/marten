module Marten
  module DB
    module Management
      module Column
        # Represents a fixed-precision numeric column.
        class Decimal < Base
          include IsBuiltInColumn

          getter max_digits
          getter decimal_places

          def initialize(
            @name : ::String,
            @max_digits : ::Int32,
            @decimal_places : ::Int32,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = false,
            @default : ::DB::Any? = nil,
          )
          end

          def clone
            self.class.new(
              @name,
              @max_digits,
              @decimal_places,
              @primary_key,
              @null,
              @unique,
              @index,
              @default
            )
          end

          def same_config?(other : Base)
            other.is_a?(Decimal) &&
              max_digits == other.max_digits &&
              decimal_places == other.decimal_places &&
              primary_key? == other.primary_key? &&
              null? == other.null? &&
              unique? == other.unique? &&
              index? == other.index? &&
              default == other.default
          end

          def serialize_args : ::String
            args = [%{#{format_string_or_symbol(name)}}, %{#{format_string_or_symbol(type)}}]
            args << %{max_digits: #{max_digits}}
            args << %{decimal_places: #{decimal_places}}
            args << %{primary_key: #{@primary_key}} if primary_key?
            args << %{null: #{@null}} if null?
            args << %{unique: #{@unique}} if unique?
            args << %{index: #{@index}} if index?
            args << %{default: #{default.inspect}} if !default.nil?
            args.join(", ")
          end

          private def db_type_parameters(connection)
            {max_digits: @max_digits, decimal_places: @decimal_places}
          end
        end
      end
    end
  end
end
