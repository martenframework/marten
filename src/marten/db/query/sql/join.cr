module Marten
  module DB
    module Query
      module SQL
        # Represents an SQL join used in the context of a specific query.
        #
        # SQL joins are managed as a tree, which means that each join can be associated with a list of underlying
        # children joins (for the joins following the considered relationship). SQL joins are "flattened" when the raw
        # SQL queries are generated.
        class Join
          @parent : Nil | self

          getter children
          getter id
          getter from_common_field
          getter from_model
          getter parent
          getter reverse_relation
          getter to_common_field
          getter to_model
          getter type

          def initialize(
            @id : Int32,
            @type : JoinType,
            @from_model : Model.class,
            @from_common_field : Field::Base,
            @reverse_relation : ReverseRelation?,
            @to_model : Model.class,
            @to_common_field : Field::Base,
            @selected : Bool,
            @table_alias_prefix = "t"
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
            to_model.local_fields.compact_map do |f|
              next unless f.db_column?
              column_name(f.db_column)
            end + children.flat_map(&.columns)
          end

          def selected?
            @selected
          end

          def table_alias : String
            "#{@table_alias_prefix}#{@id}"
          end

          def to_a : Array(self)
            [self] + @children.flat_map(&.to_a)
          end

          def to_sql : String
            statement = case @type
                        when JoinType::INNER
                          "INNER JOIN"
                        when JoinType::LEFT_OUTER
                          "LEFT OUTER JOIN"
                        end

            to_table_name = to_model.db_table
            to_table_common_column = to_common_field.db_column
            from_table_name = parent.try(&.table_alias) || from_model.db_table
            from_table_common_column = from_common_field.db_column

            sql = "#{statement} #{to_table_name} #{table_alias} " \
                  "ON (#{from_table_name}.#{from_table_common_column} = #{column_name(to_table_common_column)})"

            ([sql] + children.flat_map(&.to_sql)).join(" ")
          end

          protected setter parent
        end
      end
    end
  end
end
