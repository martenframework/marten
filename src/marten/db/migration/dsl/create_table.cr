module Marten
  module DB
    abstract class Migration
      module DSL
        class CreateTable
          def initialize(@name : String | Symbol)
          end

          def build : self
            with self yield
            self
          end

          def operation
            Operation::CreateTable.new(name: @name.to_s, columns: columns)
          end

          macro column(*args, **kwargs)
            columns << _init_column({{ args.splat }}, {{ kwargs.double_splat }})
          end

          private getter columns = [] of Management::Column::Base
        end
      end
    end
  end
end
