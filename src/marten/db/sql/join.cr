module Marten
  module DB
    module SQL
      # Represents an SQL join used in the context of a specific query.
      #
      # SQL joins are managed as a tree, which means that each join can be associated with a list of underlying
      # children joins (for the joins following the considered relationship). SQL joins are "flattened" when the raw SQL
      # queries are generated.
      class Join
        @parent : Nil | self

        getter children
        getter field
        getter model
        getter parent

        def initialize(
          @id : Int32,
          @field : Field::Base,
          @type : JoinType,
          @model : Model.class
        )
          @children = [] of self
        end

        def add_child(child : self) : Nil
          child.parent = self
          @children << child
        end

        def column_name(name) : String
          "#{table_alias}.#{name}"
        end

        def columns : Array(String)
          field.related_model.fields.map { |f| column_name(f.db_column) } + children.map(&.columns).flatten
        end

        def table_alias : String
          "t#{@id}"
        end

        def to_a : Array(self)
          [self] + @children.map(&.to_a).flatten
        end

        def to_sql : String
          statement = case @type
                      when JoinType::INNER
                        "INNER JOIN"
                      when JoinType::LEFT_OUTER
                        "LEFT OUTER JOIN"
                      end

          table_name = field.related_model.db_table
          table_pk = field.related_model.pk_field.id
          column_name = field.db_column
          parent_table_name = parent.try(&.table_alias) || model.db_table

          sql = "#{statement} #{table_name} #{table_alias} " \
                "ON (#{parent_table_name}.#{column_name} = #{column_name(table_pk)})"

          ([sql] + children.map(&.to_sql).flatten).join(" ")
        end

        protected setter parent
      end
    end
  end
end
