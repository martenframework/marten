module Marten
  module DB
    class Index
      getter name
      getter fields

      def initialize(@name : String, @fields : Array(Field::Base))
      end

      def to_management_index : Management::Index
        column_names = [] of String
        @fields.each do |field|
          column = field.to_column

          if column.nil?
            raise Errors::InvalidField.new(
              "Field '#{field.id}' cannot be used as part of an index because it is not associated with " \
              "a database column"
            )
          end

          column_names << column.not_nil!.name
        end

        Management::Index.new(@name, column_names)
      end
    end
  end
end
