module Marten
  module DB
    abstract class Model
      module Querying
        macro included
          extend Marten::DB::Model::Querying::ClassMethods

          LOOKUP_SEP = "__"

          macro inherited
            class NotFound < Marten::DB::Errors::RecordNotFound; end
          end
        end

        module ClassMethods
          def all
            QuerySet(self).new
          end

          def filter(**kwargs)
            QuerySet(self).new.filter(**kwargs)
          end

          def filter(&block)
            expr = Expression::Filter(self).new
            query : QueryNode(self) = with expr yield
            QuerySet(self).new.filter(query)
          end

          def exclude(**kwargs)
            QuerySet(self).new.exclude(**kwargs)
          end

          def exclude(&block)
            expr = Expression::Filter(self).new
            query : QueryNode(self) = with expr yield
            QuerySet(self).new.exclude(query)
          end

          def get(**kwargs)
            QuerySet(self).new.get(**kwargs)
          end

          def first
            QuerySet(self).new.first
          end

          def last
            QuerySet(self).new.last
          end
        end
      end
    end
  end
end
