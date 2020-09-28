module Marten
  module DB
    abstract class Migration
      module DSL
        macro create_table(name)
          @operations << CreateTable.new({{ name }}).build do
            {{ yield }}
          end.operation
        end
      end
    end
  end
end
