module Marten
  module DB
    module Query
      module SQL
        # Allows to iterate over the rows of a result set.
        #
        # The `RowIterator` class allows to easily iterate over each local column of a given model and each of its
        # associated relations so that they can in turn be initialized properly from their local column values when
        # selected joins are used.
        class RowIterator
          getter cursor

          def initialize(
            @model : Model.class,
            @result_set : ::DB::ResultSet,
            @joins : Array(Join),
            @annotations : Array(SQL::Annotation::Base),
            @cursor : Int32 = 0,
            @root_model : Model.class | Nil = nil,
          )
          end

          def advance
            # Here we perform a @result_set.read for each model field that should've been read as of for each possible
            # join. This is done to allow the next appropriate join relation to be read properly by the next row
            # iterator and to handle the case of null foreign keys for example.

            each_local_column { |rs, _c| rs.read(Int8 | ::DB::Any) }
            each_parent_column { |_pm, rs, _c| rs.read(Int8 | ::DB::Any) }
            each_joined_relation { |ri, _c| ri.advance }
            each_annotation { |rs, _a| rs.read(Int8 | ::DB::Any) }
          end

          def each_annotation(&)
            @annotations.each do |ann|
              yield @result_set, ann
            end
          end

          def each_joined_relation(&)
            effective_joins.each do |join|
              relation_iterator = self.class.new(
                model: join.to_model,
                result_set: @result_set,
                joins: join.children,
                annotations: Array(Annotation::Base).new,
                cursor: @cursor,
                root_model: @root_model || @model,
              )

              yield relation_iterator, join.from_common_field, join.reverse_relation

              @cursor = relation_iterator.cursor
            end
          end

          def each_local_column(&)
            @model.local_fields.count(&.db_column?).times do
              yield @result_set, @result_set.column_names[@cursor]
              @cursor += 1
            end
          end

          def each_parent_column(&)
            @model.parent_models.each do |parent_model|
              next if parent_model == @root_model

              parent_model.local_fields.count(&.db_column?).times do
                yield parent_model, @result_set, @result_set.column_names[@cursor]
                @cursor += 1
              end
            end
          end

          private def effective_joins(sub_joins : Array(Join)? = nil)
            (sub_joins || @joins).select(&.selected?).flat_map do |join|
              # We skip the join if the model has already been included in the result set, which is the case for models
              # using multi table inheritance.
              if @model.parent_models.includes?(join.to_model)
                effective_joins(join.children)
              else
                join
              end
            end
          end
        end
      end
    end
  end
end
