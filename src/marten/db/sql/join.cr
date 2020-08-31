module Marten
  module DB
    module SQL
      class Join
        def initialize(@parent_model : Model.class, @relation_field : Field::Base, @type : JoinType)
        end

        protected def to_sql
          statement = case @type
                      when JoinType::INNER
                        "INNER JOIN"
                      when JoinType::LEFT_OUTER
                        "LEFT OUTER JOIN"
                      end

          table_alias = @relation_field.relation_name
          table_name = @relation_field.related_model.table_name
          table_pk = @relation_field.related_model.pk_field.id
          column_name = @relation_field.db_column
          parent_table_name = @parent_model.table_name

          "#{statement} #{table_name} #{table_alias} " \
          "ON (#{parent_table_name}.#{column_name} = #{table_alias}.#{table_pk})"
        end
      end
    end
  end
end
