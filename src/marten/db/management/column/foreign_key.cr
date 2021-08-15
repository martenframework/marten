module Marten
  module DB
    module Management
      module Column
        class ForeignKey < Base
          include IsBuiltInColumn

          @target_column : Base? = nil
          @to_table : ::String
          @to_column : ::String

          getter to_column
          getter to_table

          def initialize(
            @name : ::String,
            to_table : ::String | Symbol,
            to_column : ::String | Symbol,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = true
          )
            @to_table = to_table.to_s
            @to_column = to_column.to_s
          end

          def clone
            cloned = self.class.new(@name, @to_table, @to_column, @primary_key, @null, @unique, @index)

            # Ensures the target column is cloned too.
            if !@target_column.nil?
              cloned.target_column = @target_column.try(&.clone)
            end

            cloned
          end

          def same_config?(other : Base)
            other.is_a?(ForeignKey) &&
              to_table == other.to_table &&
              to_column == other.to_column &&
              primary_key? == other.primary_key? &&
              null? == other.null? &&
              unique? == other.unique? &&
              index? == other.index? &&
              default == other.default
          end

          def serialize_args : ::String
            args = [%{#{format_string_or_symbol(name)}}, %{#{format_string_or_symbol(type)}}]
            args << %{to_table: #{format_string_or_symbol(to_table)}}
            args << %{to_column: #{format_string_or_symbol(to_column)}}
            args << %{primary_key: #{@primary_key}} if primary_key?
            args << %{null: #{@null}} if null?
            args << %{unique: #{@unique}} if unique?
            args << %{index: #{@index}} if !index?
            args << %{default: #{default.inspect}} if !default.nil?
            args.join(", ")
          end

          def sql_type(connection : Connection::Base) : ::String
            ensured_target_column.sql_type(connection)
          end

          def sql_type_suffix(connection : Connection::Base) : ::String?
            ensured_target_column.sql_type_suffix(connection)
          end

          # :nodoc:
          def contribute_to_project(project : ProjectState) : Nil
            target_table = project.tables.values.find { |t| t.name == to_table }.not_nil!
            @target_column = target_table.get_column(to_column).clone
            @target_column.not_nil!.primary_key = false

            if @target_column.is_a?(BigInt)
              @target_column.as(BigInt).primary_key = false
              @target_column.as(BigInt).auto = false
            elsif @target_column.is_a?(Int)
              @target_column.as(Int).primary_key = false
              @target_column.as(Int).auto = false
            end
          end

          protected setter target_column

          private def ensured_target_column
            @target_column.not_nil!
          end
        end
      end
    end
  end
end
