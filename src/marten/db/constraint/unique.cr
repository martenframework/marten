module Marten
  module DB
    module Constraint
      class Unique
        getter name
        getter fields

        def initialize(@name : String, @fields : Array(Field::Base))
        end

        # Returns a clone of the current unique constraint.
        def clone
          Unique.new(name: name, fields: fields)
        end

        def to_management_constraint : Management::Constraint::Unique
          column_names = [] of String
          @fields.each do |field|
            column = field.to_column

            if column.nil?
              raise Errors::InvalidField.new(
                "Field '#{field.id}' cannot be used as part of a unique constraint because it is not associated with " \
                "a database column"
              )
            end

            column_names << column.not_nil!.name
          end

          Management::Constraint::Unique.new(@name, column_names)
        end
      end
    end
  end
end
