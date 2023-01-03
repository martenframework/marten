module Marten
  module DB
    abstract class Migration
      module DSL
        class CreateTable
          def initialize(@name : String | Symbol)
          end

          def build(&) : self
            with self yield
            self
          end

          def operation
            Operation::CreateTable.new(
              name: @name.to_s,
              columns: columns,
              unique_constraints: unique_constraints,
              indexes: indexes
            )
          end

          macro column(*args, **kwargs)
            columns << _init_column({{ args.splat }}, {{ kwargs.double_splat }})
          end

          macro index(name, column_names)
            indexes << _init_index({{ name }}, {{ column_names }})
          end

          macro unique_constraint(name, column_names)
            unique_constraints << _init_unique_constraint({{ name }}, {{ column_names }})
          end

          private getter columns = [] of Management::Column::Base
          private getter indexes = [] of Management::Index
          private getter unique_constraints = [] of Management::Constraint::Unique
        end
      end
    end
  end
end
