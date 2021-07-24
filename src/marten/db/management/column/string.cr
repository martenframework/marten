module Marten
  module DB
    module Management
      module Column
        class String < Base
          include IsBuiltInColumn

          getter max_size

          def initialize(
            @name : ::String,
            @max_size : ::Int32,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = false,
            @default : ::DB::Any? = nil
          )
          end

          def clone
            self.class.new(@name, @max_size, @primary_key, @null, @unique, @index, @default)
          end

          def same_config?(other : Base)
            other.is_a?(String) &&
              max_size == other.max_size &&
              primary_key? == other.primary_key? &&
              null? == other.null? &&
              unique? == other.unique? &&
              index? == other.index? &&
              default == other.default
          end

          def serialize_args : ::String
            args = [%{#{format_string_or_symbol(name)}}, %{#{format_string_or_symbol(type)}}]
            args << %{max_size: #{max_size}}
            args << %{primary_key: #{@primary_key}} if primary_key?
            args << %{null: #{@null}} if null?
            args << %{unique: #{@unique}} if unique?
            args << %{index: #{@index}} if index?
            args << %{default: #{default.inspect}} if !default.nil?
            args.join(", ")
          end

          private def db_type_parameters
            {max_size: @max_size}
          end
        end
      end
    end
  end
end
