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
          # Returns a queryset targetting all the records for the considered model.
          #
          # This method returns a `Marten::DB::QuerySet` object that - if evaluated - will return all the records for
          # the considered model.
          def all
            QuerySet(self).new
          end

          # Returns a queryset that will be evaluated using the specified database.
          #
          # A valid database alias must be used here (it must correspond to an ID of a database configured in the
          # project settings). If the passed database alias doesn't correspond to any defined connections, a
          # `Marten::DB::Errors::UnknownConnection` error will be raised.
          def using(db : String | Symbol)
            all.using(db)
          end

          # Returns a queryset whose specified `relations` are "followed" and joined to each result.
          #
          # When using `#join`, the specified foreign-key relationships will be followed and each record returned by the
          # queryset will have the corresponding related objects already selected and populated. Using `#join` can
          # result in performance improvements since it can help reduce the number of SQL queries, as illustrated by the
          # following example:
          #
          # ```
          # p1 = Post.get(id: 1)
          # puts p1.author # hits the database to retrieved the related "author"
          #
          # p2 = Post.join(:author).get(id: 1)
          # puts p2.author # doesn't hit the database since the related "author" was already selected
          # ```
          #
          # It should be noted that it is also possible to follow foreign keys of direct related models too by using the
          # double underscores notation(`__`). For example the following query will select the joined "author" and its
          # associated "profile":
          #
          # ```
          # Post.join(:author__profile)
          # ```
          def join(*relations : String | Symbol)
            all.join(*relations)
          end

          # Returns a queryset matching a specific set of filters.
          #
          # This method returns a `Marten::DB::QuerySet` object. The filters passed to this method method must be
          # specified using the predicate format:
          #
          # ```
          # Post.filter(title: "Test")
          # Post.filter(title__startswith: "A")
          # ```
          #
          # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
          def filter(**kwargs)
            QuerySet(self).new.filter(**kwargs)
          end

          # Returns a queryset matching a specific set of advanced filters.
          #
          # This method returns a `Marten::DB::QuerySet` object and allows to define complex database queries involving
          # **AND** and **OR** operators. It yields a block where each filter has to be wrapped using a `q(...)`
          # expression. These expressions can then be used to build complex queries such as:
          #
          # ```
          # Post.filter { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
          # ```
          def filter(&block)
            expr = Expression::Filter(self).new
            query : QueryNode(self) = with expr yield
            QuerySet(self).new.filter(query)
          end

          # Returns a queryset whose records do not match the given set of filters.
          #
          # This method returns a `Marten::DB::QuerySet` object. The filters passed to this method method must be
          # specified using the predicate format:
          #
          # ```
          # Post.exclude(title: "Test")
          # Post.exclude(title__startswith: "A")
          # ```
          #
          # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
          def exclude(**kwargs)
            QuerySet(self).new.exclude(**kwargs)
          end

          # Returns a queryset whose records do not match the given set of advanced filters.
          #
          # This method returns a `Marten::DB::QuerySet` object and allows to define complex database queries involving
          # **AND** and **OR** operators. It yields a block where each filter has to be wrapped using a `q(...)`
          # expression. These expressions can then be used to build complex queries such as:
          #
          # ```
          # Post.exclude { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
          # ```
          def exclude(&block)
            expr = Expression::Filter(self).new
            query : QueryNode(self) = with expr yield
            QuerySet(self).new.exclude(query)
          end

          # Returns the model instance matching the given set of filters.
          #
          # Model fields such as primary keys or fields with a unique constraint should be used here in order to
          # retrieve a specific record:
          #
          # ```
          # post_1 = Post.get(id: 123)
          # post_2 = Post.get(id: 456, is_published: false)
          # ```
          #
          # If the specified set of filters doesn't match any records, the returned value will be `nil`.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get(**kwargs)
            QuerySet(self).new.get(**kwargs)
          end

          # Returns the model instance matching the given set of filters.
          #
          # Model fields such as primary keys or fields with a unique constraint should be used here in order to
          # retrieve a specific record:
          #
          # ```
          # post_1 = Post.get!(id: 123)
          # post_2 = Post.get!(id: 456, is_published: false)
          # ```
          #
          # If the specified set of filters doesn't match any records, a `Marten::DB::Errors::RecordNotFound` exception
          # will be raised.
          #
          # In order to ensure data consistency, this method will also raise a
          # `Marten::DB::Errors::MultipleRecordsFound` exception if multiple records match the specified set of filters.
          def get!(**kwargs)
            QuerySet(self).new.get!(**kwargs)
          end

          # Returns the first record for the considered model.
          #
          # `nil` will be returned if no records can be found.
          def first
            QuerySet(self).new.first
          end

          # Returns the last record for the considered model.
          #
          # `nil` will be returned if no records can be found.
          def last
            QuerySet(self).new.last
          end
        end
      end
    end
  end
end
