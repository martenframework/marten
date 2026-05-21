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
                case lo = @left_operand
                when Annotation::Base
                  lo.field.to_db(o)
                when Transformation::Base
                  lo.as(Transformation::Base).bind_parameter_value(o)
                else
                  lo.as(Field::Base).to_db(o)
                end
              end
            end
          end
        end
      end
    end
  end
end
