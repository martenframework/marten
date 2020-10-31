module Marten
  module DB
    module Management
      class Statement
        class ForeignKeyName < Reference
          def initialize(
            @index_name_proc : Proc(String, Array(String), String, String),
            @table : String,
            @column : String,
            @to_table : String,
            @to_column : String
          )
          end

          def to_s
            IndexName.new(@index_name_proc, @table, [@column], "_fk_#{@to_table}_#{@to_column}").to_s
          end
        end
      end
    end
  end
end
