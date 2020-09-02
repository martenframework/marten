module Marten
  module DB
    module SQL
      class Join
        def initialize(@id : Int32, @parent_model : Model.class, @relation_field : Field::Base, @type : JoinType)
        end

        protected getter parent_model
        protected getter relation_field

        protected def column_name(name)
          "#{table_alias}.#{name}"
        end

        protected def columns
          relation_field.related_model.fields.map { |f| column_name(f.db_column) }
        end

        protected def to_sql
          statement = case @type
                      when JoinType::INNER
                        "INNER JOIN"
                      when JoinType::LEFT_OUTER
                        "LEFT OUTER JOIN"
                      end

          table_name = @relation_field.related_model.table_name
          table_pk = @relation_field.related_model.pk_field.id
          column_name = @relation_field.db_column
          parent_table_name = @parent_model.table_name

          "#{statement} #{table_name} #{table_alias} " \
          "ON (#{parent_table_name}.#{column_name} = #{column_name(table_pk)})"
        end

        private def table_alias
          "t#{@id}"
        end
      end
    end
  end
end
