module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class In < Base
            predicate_name "in"

            def to_sql(connection : Connection::Base)
              if !@right_operand.is_a?(Array(Field::Any))
                raise Errors::UnmetQuerySetCondition.new("In predicate requires an array of values")
              end

              raise Errors::EmptyResults.new if @right_operand.as?(Array(Field::Any)).try(&.empty?)

              super
            end

            private def sql_right_operand(_connection)
              String.build do |s|
                s << "IN ( "
                s << @right_operand.as(Array(Field::Any)).join(" , ") { "%s" }
                s << " )"
              end
            end

            private def sql_right_operand_param(_connection)
              @right_operand.as(Array(Field::Any)).map do |o|
                if @left_operand.is_a?(Annotation::Base)
                  @left_operand.as(Annotation::Base).field.to_db(o)
                else
                  @left_operand.as(Field::Base).to_db(o)
                end
              end
            end
          end
        end
      end
    end
  end
end
