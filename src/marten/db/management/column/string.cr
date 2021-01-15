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
            @index = false
          )
          end

          def clone
            self.class.new(@name, @max_size, @primary_key, @null, @unique, @index)
          end

          def serialize_args : ::String
            args = [%{"#{name}"}, %{"#{type}"}]
            args << %{max_size: #{max_size}}
            args << %{primary_key: #{@primary_key}} if primary_key?
            args << %{null: #{@null}} if null?
            args << %{unique: #{@unique}} if unique?
            args << %{index: #{@index}} if index?
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
