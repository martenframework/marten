module Marten
  module DB
    abstract class Model
      module Querying
        macro included
          extend Marten::DB::Model::Querying::ClassMethods

          _begin_scoped_querysets_setup

          macro inherited
            _begin_scoped_querysets_setup
            _inherit_scoped_querysets

            macro finished
              _finish_scoped_querysets_setup
            end
          end

          macro finished
            _finish_scoped_querysets_setup
          end
        end

        module ClassMethods
          # :nodoc:
          def _base_query
            {% begin %}
            {% if @type.abstract? %}
            raise "Records can only be queried from non-abstract model classes"
            {% else %}
            Query::SQL::Query({{ @type }}).new
            {% end %}
            {% end %}
          end

          # :nodoc:
          # Returns a base queryset that intentionally targets all the records in the database for the model at hand.
          # Although this method is public (because it's generated for all models), it is used internally by Marten to
          # ensure correct behaviours when deleting records.
          def _base_queryset
            {% begin %}
            {% if @type.abstract? %}
            raise "Records can only be queried from non-abstract model classes"
            {% else %}
            Query::Set({{ @type }}).new
            {% end %}
            {% end %}
          end

          # Returns a queryset targeting all the records for the considered model.
          #
          # This method returns a `Marten::DB::Query::Set` object that - if evaluated - will return all the records for
          # the considered model.
          def all
            default_queryset
          end

          # Returns a new query set with the specified annotations.
          #
          # This method returns a new query set with the specified annotations. The annotations are specified using a
          # block where each annotation has to be wrapped using the `annotate` method. For example:
          #
          # ```
          # query_set = Book.annotate { count(:authors) }
          # other_query_set = Book.annotate do
          #   count(:authors, alias_name: :author_count)
          #   sum(:pages, alias_name: :total_pages)
          # end
          # ```
          #
          # Each of the specified annotations is then available for further use in the query set (in order to filter or
          # order the records). The annotations are also available in retrieved model records via the `#annotations`
          # method, which returns a hash containing the annotations as keys and their values as values.
          def annotate(&)
            expr = Query::Expression::Annotate.new
            with expr yield

            default_queryset.annotate(expr)
          end

          # Returns `true` if the model query set matches at least one record or `false` otherwise. Alias of `#exists?`.
          def any?
            exists?
          end

          # Returns the average of a field for the current model
          #
          # This method calculates the average value of the specified field for the considered model. For example:
          #
          # ```
          # Product.average(:price) # => 25.0
          # ```
          #
          # This will return the average price of all products in the database.
          def average(field : String | Symbol)
            default_queryset.average(field)
          end

          # Bulk inserts the passed model instances into the database.
          #
          # This method allows to insert multiple model instances into the database in a single query. This can be
          # useful when dealing with large amounts of data that need to be inserted into the database. For example:
          #
          # ```
          # Post.bulk_create(
          #   [
          #     Post.new(title: "First post"),
          #     Post.new(title: "Second post"),
          #     Post.new(title: "Third post"),
          #   ]
          # )
          # ```
          #
          # An optional `batch_size` argument can be passed to this method in order to specify the number of records
          # that should be inserted in a single query. By default, all records are inserted in a single query (except
          # for SQLite databases where the limit of variables in a single query is 999). For example:
          #
          # ```
          # Post.bulk_create(
          #   [
          #     Post.new(title: "First post"),
          #     Post.new(title: "Second post"),
          #     Post.new(title: "Third post"),
          #   ],
          #   batch_size: 2
          # )
          # ```
          def bulk_create(objects : Array(self), batch_size : Int32? = nil)
            default_queryset.bulk_create(objects, batch_size)
          end

          # Returns the total count of records for the considered model.
          #
          # This method returns the total count of records for the considered model. If a field is specified, the method
          # will return the total count of records for which the specified field is not `nil`. For example:
          #
          # ```
          # Post.count              # => 3
          # Post.count(:updated_by) # => 2
          # ```
          def count(field : String | Symbol | Nil = nil)
            default_queryset.count(field)
          end

          # Returns the default queryset to use when creating "unfiltered" querysets for the model at hand.
          def default_queryset
            unscoped
          end

          # Returns a queryset whose records do not match the given set of filters.
          #
          # This method returns a `Marten::DB::Query::Set` object. The filters passed to this method method must be
          # specified using the predicate format:
          #
          # ```
          # Post.exclude(title: "Test")
          # Post.exclude(title__startswith: "A")
          # ```
          #
          # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
          def exclude(**kwargs)
            default_queryset.exclude(**kwargs)
          end

          # Returns a queryset whose records do not match the given set of advanced filters.
          #
          # This method returns a `Marten::DB::Query::Set` object and allows to define complex database queries
          # involving **AND** and **OR** operators. It yields a block where each filter has to be wrapped using a
          # `q(...)` expression. These expressions can then be used to build complex queries such as:
          #
          # ```
          # Post.exclude { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
          # ```
          def exclude(&)
            expr = Query::Expression::Filter.new
            query : Query::Node = with expr yield
            default_queryset.exclude(query)
          end

          # Returns `true` if the default model query set matches at least one record, or `false` otherwise.
          def exists?
            default_queryset.exists?
          end

          # Returns `true` if the query set corresponding to the specified filters matches at least one record.
          #
          # This method returns `true` if the filters passed to this method match at least one record. These filters
          # must be specified using the predicate format:
          #
          # ```
          # Post.exists?(title: "Test")
          # Post.exists?(title__startswith: "A")
          # ```
          #
          # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
          def exists?(**kwargs)
            default_queryset.exists?(**kwargs)
          end

          # Returns `true` if the query set corresponding to the specified advanced filters matches at least one record.
          #
          # This method returns a `Bool` object and allows to define complex database queries involving **AND** and
          # **OR** operators. It yields a block where each filter has to be wrapped using a `q(...)` expression. These
          # expressions can then be used to build complex queries such as:
          #
          # ```
          # Post.exists? { (q(name: "Foo") | q(name: "Bar")) & q(is_published: true) }
          # ```
          def exists?(&)
            expr = Query::Expression::Filter.new
            query : Query::Node = with expr yield
            default_queryset.filter(query).exists?
          end

          # Returns a queryset matching a specific set of filters.
          #
          # This method returns a `Marten::DB::Query::Set` object. The filters passed to this method method must be
          # specified using the predicate format:
          #
          # ```
          # Post.filter(title: "Test")
          # Post.filter(title__startswith: "A")
          # ```
          #
          # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
          def filter(**kwargs)
            default_queryset.filter(**kwargs)
          end

          # Returns a query set whose records match the given raw predicate and named parameters.
          #
          # This method enables filtering based on raw SQL predicates, offering greater flexibility than standard field
          # predicates. It returns a modified `Marten::DB::Query::Set`.
          #
          # For example:
          #
          # ```
          # query_set = Post.all
          # query_set.filter("is_published = true")
          # ```
          def filter(raw_predicate : String)
            default_queryset.filter(raw_predicate)
          end

          # Returns a query set whose records match the given raw predicate and named parameters.
          #
          # This method enables filtering based on raw SQL predicates, offering greater flexibility than standard field
          # predicates. It returns a modified `Marten::DB::Query::Set`.
          #
          # For example:
          #
          # ```
          # query_set = Post.all
          # query_set.filter("is_published = ?", true)
          # ```
          def filter(raw_predicate : String, *args)
            default_queryset.filter(raw_predicate, *args)
          end

          # Returns a query set whose records match the given raw predicate and named parameters.
          #
          # This method enables filtering based on raw SQL predicates, offering greater flexibility than standard field
          # predicates. It returns a modified `Marten::DB::Query::Set`.
          #
          # For example:
          #
          # ```
          # query_set = Post.all
          # query_set.filter("is_published = :published", published: true)
          # ```
          def filter(raw_predicate : String, **kwargs)
            default_queryset.filter(raw_predicate, **kwargs)
          end

          # Returns a query set whose records match the given raw predicate and named parameters.
          #
          # This method enables filtering based on raw SQL predicates, offering greater flexibility than standard field
          # predicates. It returns a modified `Marten::DB::Query::Set`.
          #
          # For example:
          #
          # ```
          # query_set = Post.all
          # query_set.filter("is_published = ?", [true])
          # ```
          def filter(raw_predicate : String, params : Array)
            default_queryset.filter(raw_predicate, params)
          end

          # Returns a query set whose records match the given raw predicate and named parameters.
          #
          # This method enables filtering based on raw SQL predicates, offering greater flexibility than standard field
          # predicates. It returns a modified `Marten::DB::Query::Set`.
          #
          # For example:
          #
          # ```
          # query_set = Post.all
          # query_set.filter("is_published = :published", {published: true})
          # ```
          def filter(raw_predicate : String, params : Hash | NamedTuple)
            default_queryset.filter(raw_predicate, params)
          end

          # Returns a queryset matching a specific set of advanced filters.
          #
          # This method returns a `Marten::DB::Query::Set` object and allows to define complex database queries
          # involving **AND** and **OR** operators. It yields a block where each filter has to be wrapped using a
          # `q(...)` expression. These expressions can then be used to build complex queries such as:
          #
          # ```
          # Post.filter { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
          # ```
          def filter(&)
            expr = Query::Expression::Filter.new
            query : Query::Node = with expr yield
            default_queryset.filter(query)
          end

          # Returns the first record for the considered model.
          #
          # `nil` will be returned if no records can be found.
          def first
            default_queryset.first
          end

          # Returns the first record for the considered model.
          #
          # A `NilAssertionError` error will be raised if no records can be found.
          def first!
            first.not_nil!
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
            default_queryset.get(**kwargs)
          end

          # Returns a single model instance matching the given raw SQL predicate.
          #
          # Returns `nil` if no record matches.
          #
          # For example:
          #
          # ```
          # post = Post.get("is_published = true")
          # ```
          def get(raw_predicate : String)
            default_queryset.get(raw_predicate)
          end

          # Returns a single model instance matching the given raw SQL predicate with positional arguments.
          #
          # Returns `nil` if no record matches.
          #
          # For example:
          # ```
          # post = Post.get("name = ?", "crystal")
          # ```
          def get(raw_predicate : String, *args)
            default_queryset.get(raw_predicate, *args)
          end

          # Returns a single model instance matching the given raw SQL predicate with positional parameters.
          #
          # Returns `nil` if no record matches.
          #
          # For example:
          #
          # ```
          # post = Post.get("name = ? AND is_published = ?", ["crystal", true])
          # ```
          def get(raw_predicate : String, params : Array)
            default_queryset.get(raw_predicate, params)
          end

          # Returns a single model instance matching the given raw SQL predicate with named parameters.
          #
          # Returns `nil` if no record matches.
          #
          # For example:
          #
          # ```
          # post = Post.get("name = :name AND is_published = :published", name: "crystal", published: true)
          # ```
          def get(raw_predicate : String, **kwargs)
            default_queryset.get(raw_predicate, **kwargs)
          end

          # Returns a single model instance matching the given raw SQL predicate with a named parameters hash.
          # Returns `nil` if no record matches.
          #
          # For example:
          #
          # ```
          # post = Post.get("name = :name", {name: "crystal"})
          # ```
          def get(raw_predicate : String, params : Hash | NamedTuple)
            default_queryset.get(raw_predicate, params)
          end

          # Returns the model instance matching a specific set of advanced filters.
          #
          # Model fields such as primary keys or fields with a unique constraint should be used here in order to
          # retrieve a specific record:
          #
          # ```
          # post_1 = Post.get { q(id: 123) }
          # post_2 = Post.get { q(id: 456, is_published: false) }
          # ```
          #
          # If the specified set of filters doesn't match any records, the returned value will be `nil`.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get(&)
            expr = Query::Expression::Filter.new
            query : Query::Node = with expr yield
            default_queryset.get(query)
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
            default_queryset.get!(**kwargs)
          end

          # Returns a single model instance matching the given raw SQL predicate.
          #
          # If the specified raw SQL predicate doesn't match any records, a `Marten::DB::Errors::RecordNotFound`
          # exception will be raised.
          #
          # For example:
          #
          # ```
          # post = Post.get!("is_published = true")
          # ```
          def get!(raw_predicate : String)
            default_queryset.get!(raw_predicate)
          end

          # Returns a single model instance matching the given raw SQL predicate with positional arguments.
          #
          # If the specified raw SQL predicate doesn't match any records, a `Marten::DB::Errors::RecordNotFound`
          # exception will be raised.
          #
          # For example:
          #
          # ```
          # post = Post.get!("name = ?", "crystal")
          # ```
          def get!(raw_predicate : String, *args)
            default_queryset.get!(raw_predicate, *args)
          end

          # Returns a single model instance matching the given raw SQL predicate with positional parameters.
          #
          # If the specified raw SQL predicate doesn't match any records, a `Marten::DB::Errors::RecordNotFound`
          # exception will be raised.
          #
          # For example:
          #
          # ```
          # post = Post.get!("name = ? AND is_published = ?", ["crystal", true])
          # ```
          def get!(raw_predicate : String, params : Array)
            default_queryset.get!(raw_predicate, params)
          end

          # Returns a single model instance matching the given raw SQL predicate with named parameters.
          #
          # If the specified raw SQL predicate doesn't match any records, a `Marten::DB::Errors::RecordNotFound`
          # exception will be raised.
          #
          # For example:
          #
          # ```
          # post = Post.get!("name = :name AND is_published = :published", name: "crystal", published: true)
          # ```
          def get!(raw_predicate : String, **kwargs)
            default_queryset.get!(raw_predicate, **kwargs)
          end

          # Returns a single model instance matching the given raw SQL predicate with a named parameters hash.
          #
          # If the specified raw SQL predicate doesn't match any records, a `Marten::DB::Errors::RecordNotFound`
          # exception will be raised.
          #
          # For example:
          #
          # ```
          # post = Post.get!("name = :name", {name: "crystal"})
          # ```
          def get!(raw_predicate : String, params : Hash | NamedTuple)
            default_queryset.get!(raw_predicate, params)
          end

          # Returns the model instance matching a specific set of advanced filters.
          #
          # Model fields such as primary keys or fields with a unique constraint should be used here in order to
          # retrieve a specific record:
          #
          # ```
          # post_1 = Post.get! { q(id: 123) }
          # post_2 = Post.get! { q(id: 456, is_published: false) }
          # ```
          #
          # If the specified set of filters doesn't match any records, a `Marten::DB::Errors::RecordNotFound` exception
          # will be raised.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get!(&)
            expr = Query::Expression::Filter.new
            query : Query::Node = with expr yield
            default_queryset.get!(query)
          end

          # Returns the model record matching the given set of filters or create a new one if no one is found.
          #
          # Model fields that uniquely identify a record should be used here. For example:
          #
          # ```
          # tag = Tag.get_or_create(label: "crystal")
          # ```
          #
          # When no record is found, the new model instance is initialized by using the attributes defined in the
          # `kwargs` double splat argument. Regardless of whether it is valid or not (and thus persisted to the database
          # or not), the initialized model instance is returned by this method.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get_or_create(**kwargs)
            default_queryset.get!(Query::Node.new(**kwargs))
          rescue Errors::RecordNotFound
            create(**kwargs)
          end

          # Returns the model record matching the given set of filters or create a new one if no one is found.
          #
          # Model fields that uniquely identify a record should be used here. The provided block can be used to
          # initialize the model instance to create (in case no record is found). For example:
          #
          # ```
          # tag = Tag.get_or_create(label: "crystal") do |new_tag|
          #   new_tag.active = false
          # end
          # ```
          #
          # When no record is found, the new model instance is initialized by using the attributes defined in the
          # `kwargs` double splat argument. Regardless of whether it is valid or not (and thus persisted to the database
          # or not), the initialized model instance is returned by this method.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get_or_create(**kwargs, &)
            default_queryset.get!(Query::Node.new(**kwargs))
          rescue Errors::RecordNotFound
            create(**kwargs) { |r| yield r }
          end

          # Returns the model record matching the given set of filters or create a new one if no one is found.
          #
          # Model fields that uniquely identify a record should be used here. For example:
          #
          # ```
          # tag = Tag.get_or_create!(label: "crystal")
          # ```
          #
          # When no record is found, the new model instance is initialized by using the attributes defined in the
          # `kwargs` double splat argument. If the new model instance is valid, it is persisted to the database ;
          # otherwise a `Marten::DB::Errors::InvalidRecord` exception is raised.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get_or_create!(**kwargs)
            default_queryset.get!(Query::Node.new(**kwargs))
          rescue Errors::RecordNotFound
            create!(**kwargs)
          end

          # Returns the model record matching the given set of filters or create a new one if no one is found.
          #
          # Model fields that uniquely identify a record should be used here. The provided block can be used to
          # initialize the model instance to create (in case no record is found). For example:
          #
          # ```
          # tag = Tag.get_or_create!(label: "crystal") do |new_tag|
          #   new_tag.active = false
          # end
          # ```
          #
          # When no record is found, the new model instance is initialized by using the attributes defined in the
          # `kwargs` double splat argument. If the new model instance is valid, it is persisted to the database ;
          # otherwise a `Marten::DB::Errors::InvalidRecord` exception is raised.
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def get_or_create!(**kwargs, &)
            default_queryset.get!(Query::Node.new(**kwargs))
          rescue Errors::RecordNotFound
            create!(**kwargs) { |r| yield r }
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

          # Returns the last record for the considered model.
          #
          # `nil` will be returned if no records can be found.
          def last
            default_queryset.last
          end

          # Returns the last record for the considered model.
          #
          # A `NilAssertionError` error will be raised if no records can be found.
          def last!
            last.not_nil!
          end

          # Returns a queryset that will limit the number of records returned.
          #
          # This method allows to specify the maximum number of records to return. For example:
          #
          # ```
          # posts = Post.limit(10)
          # ```
          #
          # In the above example, only the first 10 records will be returned.
          def limit(value : Int)
            default_queryset.limit(value)
          end

          # Returns the maximum value of a field for the current model.
          #
          # Finds the largest value within the specified field for the records targeted by the model. For example:
          #
          # ```
          # Product.maximum(:price) # => 250.0
          # ```
          #
          # This would identify the highest-priced product.
          def maximum(field : String | Symbol)
            default_queryset.maximum(field)
          end

          # Returns the minimum value of a field for the current model.
          #
          # Finds the smallest value within the specified field for the records targeted by the model. For example:
          #
          # ```
          # Product.minimum(:price) # => 250.0
          # ```
          #
          # This would identify the lowest-priced product.
          def minimum(field : String | Symbol)
            default_queryset.minimum(field)
          end

          # Returns a queryset that will offset the records returned.
          #
          # This method allows to specify the starting point for the records to return. For example:
          #
          # ```
          # posts = Post.offset(10)
          # ```
          #
          # In the above example, the records will be returned starting from the 10th record.
          def offset(value : Int)
            default_queryset.offset(value)
          end

          # Returns a queryset targeting all the records for the considered model with the specified ordering.
          #
          # Multiple fields can be specified in order to define the final ordering. For example:
          #
          # ```
          # query_set = Post.order("-published_at", "title")
          # ```
          #
          # In the above example, records would be ordered by descending publication date, and then by title
          # (ascending).
          def order(*fields : String | Symbol)
            default_queryset.order(fields.to_a)
          end

          # Returns a queryset targeting all the records for the considered model with the specified ordering.
          #
          # Multiple fields can be specified in order to define the final ordering. For example:
          #
          # ```
          # query_set = Post.order(["-published_at", "title"])
          # ```
          #
          # In the above example, records would be ordered by descending publication date, and then by title
          # (ascending).
          def order(fields : Array(String | Symbol))
            default_queryset.order(fields.map(&.to_s))
          end

          # Returns the primary key values of the considered model records.
          #
          # This method returns an array containing the primary key values of the model records. For example:
          #
          # ```
          # Post.pks # => [1, 2, 3]
          # ```
          def pks
            pluck(:pk).map(&.first)
          end

          # Returns specific column values without loading entire record objects.
          #
          # This method allows to easily select specific column values from the current query set. This allows
          # retrieving specific column values without actually loading entire records. The method returns an array
          # containing one array with the actual column values for each record. For example:
          #
          # ```
          # Post.pluck("title", "published")
          # # => [["First article", true], ["Upcoming article", false]]
          # ```
          def pluck(*fields : String | Symbol) : Array(Array(Field::Any))
            default_queryset.pluck(fields.to_a)
          end

          # Returns specific column values without loading entire record objects.
          #
          # This method allows to easily select specific column values from the current query set. This allows
          # retrieving specific column values without actually loading entire records. The method returns an array
          # containing one array with the actual column values for each record. For example:
          #
          # ```
          # Post.pluck(["title", "published"])
          # # => [["First article", true], ["Upcoming article", false]]
          # ```
          def pluck(fields : Array(String | Symbol)) : Array(Array(Field::Any))
            default_queryset.pluck(fields)
          end

          # Returns a queryset that will prefetch in a single batch the records for the specified relations.
          #
          # When using `#prefetch`, the records corresponding to the specified relationships will be prefetched in
          # single batches and each record returned by the queryset will have the corresponding related objects already
          # selected and populated. Using `#prefetch` can result in performance improvements since it can help reduce
          # the number of SQL queries, as illustrated by the following example:
          #
          # ```
          # posts_1 = Post.all.to_a
          # puts posts_1[0].tags.to_a # hits the database to retrieve the related "tags" (many-to-many relation)
          #
          # posts_2 = Post.prefetch(:tags).to_a
          # puts posts_2[0].tags # doesn't hit the database since the related "tags" relation was already prefetched
          # ```
          #
          # It should be noted that it is also possible to follow relations and reverse relations too by using the
          # double underscores notation(`__`). For example the following query will prefetch the "author" relation and
          # then the "favorite tags" relation of the author records:
          #
          # ```
          # Post.prefetch(:author__favorite_tags)
          # ```
          #
          # Finally, it is worth mentioning that multiple relations can be specified to `#prefetch`. For example:
          #
          # ```
          # Author.prefetch(:books__genres, :publisher)
          # ```
          def prefetch(*relations : String | Symbol)
            all.prefetch(*relations)
          end

          # Returns a queryset that will automatically prefetch in a single batch the records for the
          # specified relation, with a custom queryset to control how the related records are queried.
          # The prefetched records will be populated on the returned queryset. Using this method can result in
          # performance improvements by reducing the number of SQL queries, as illustrated by the following example:
          #
          # ```
          # # Prefetching with a custom queryset
          # posts = Post.all.prefetch(:tags, query_set: Tag.order(:name)).to_a
          # puts posts[0].tags # Prefetched with custom ordering
          # ```
          #
          # It should be noted that this method enforces type-checking for the custom queryset to ensure its
          # model matches the relation being prefetched. If a type mismatch is detected, a
          # `Marten::DB::Errors::UnmetQuerySetCondition` exception will be raised. For example:
          #
          # ```
          # # Valid usage
          # posts = Post.all.prefetch(:tags, query_set: Tag.order(:name))
          #
          # # Invalid usage: Type mismatch
          # posts = Post.all.prefetch(:tags, query_set: Comment.order(:created_at))
          # # Raises Marten::DB::Errors::UnmetQuerySetCondition:
          # # "Can't prefetch :tags using Comment query set."
          # ```
          def prefetch(relation_name : String | Symbol, query_set : Query::Set::Any)
            all.prefetch(relation_name, query_set)
          end

          # Returns a raw query set for the passed SQL query and optional positional parameters.
          #
          # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
          # matched by the passed SQL query. For example:
          #
          # ```
          # Article.raw("SELECT * FROM articles")
          # ```
          #
          # Additional positional parameters can also be specified if the query needs to be parameterized. For example:
          #
          # ```
          # Article.raw("SELECT * FROM articles WHERE title = ? and created_at > ?", "Hello World!", "2022-10-30")
          # ```
          def raw(query : String, *args)
            default_queryset.raw(query, args.to_a)
          end

          # Returns a raw query set for the passed SQL query and optional named parameters.
          #
          # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
          # matched by the passed SQL query. For example:
          #
          # ```
          # Article.raw("SELECT * FROM articles")
          # ```
          #
          # Additional named parameters can also be specified if the query needs to be parameterized. For example:
          #
          # ```
          # Article.raw(
          #   "SELECT * FROM articles WHERE title = :title and created_at > :created_at",
          #   title: "Hello World!",
          #   created_at: "2022-10-30"
          # )
          # ```
          def raw(query : String, **kwargs)
            default_queryset.raw(query, kwargs.to_h)
          end

          # Returns a raw query set for the passed SQL query and positional parameters.
          #
          # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
          # matched by the passed SQL query and associated positional parameters. For example:
          #
          # ```
          # Article.raw("SELECT * FROM articles WHERE title = ? and created_at > ?", ["Hello World!", "2022-10-30"])
          # ```
          def raw(query : String, params : Array)
            default_queryset.raw(query, params)
          end

          # Returns a raw query set for the passed SQL query and named parameters.
          #
          # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
          # matched by the passed SQL query and associated named parameters. For example:
          #
          # ```
          # Article.raw(
          #   "SELECT * FROM articles WHERE title = :title and created_at > :created_at",
          #   {
          #     title:      "Hello World!",
          #     created_at: "2022-10-30",
          #   }
          # )
          # ```
          def raw(query : String, params : Hash | NamedTuple)
            default_queryset.raw(query, params)
          end

          # Returns the sum of a field for the current model
          #
          # This method calculates the total sum of the specified field's values for the considered model. For example:
          #
          # ```
          # Product.sum(:price) # => 2500  (Assuming there are 100 products with prices averaging to 25)
          # ```
          def sum(field : String | Symbol)
            default_queryset.sum(field)
          end

          # Returns an unscoped queryset for the considered model.
          def unscoped
            {% begin %}
            {% if @type.abstract? %}
            raise "Records can only be queried from non-abstract model classes"
            {% else %}
            {{ @type }}::QuerySet.new
            {% end %}
            {% end %}
          end

          # Updates all the records with the passed values.
          #
          # This method allows to update all the records with a hash or a named tuple of values. It returns the number
          # of records that were updated:
          #
          # ```
          # Post.update({"title" => "Updated"})
          # ```
          #
          # It should be noted that this methods results in a regular `UPDATE` SQL statement. As such, the records that
          # are updated through the use of this method won't be validated, and no callbacks will be executed for them
          # either.
          def update(values : Hash | NamedTuple)
            default_queryset.update(values)
          end

          # Updates all the records with the passed values.
          #
          # This method allows to update all the records with the values defined in the `kwargs` double splat argument.
          # It returns the number of records that were updated:
          #
          # ```
          # Post.update(title: "Updated")
          # ```
          #
          # It should be noted that this methods results in a regular `UPDATE` SQL statement. As such, the records that
          # are updated through the use of this method won't be validated, and no callbacks will be executed for them
          # either.
          def update(**kwargs)
            default_queryset.update(kwargs.to_h)
          end

          # Updates a model record matching the given filters or creates a new one if no one is found.
          #
          # This method first attempts to retrieve a record that matches the specified filters. If it exists,
          # the record is updated using the attributes provided via the required `updates` argument.
          # If no matching record is found, a new one is created using the attributes defined in `updates`:
          #
          # ```
          # person = Person.update_or_create(updates: {first_name: "Bob"}, first_name: "John", last_name: "Doe")
          # ```
          #
          # If additional attributes should only be used when creating new records, a `defaults` argument can be
          # provided (these attributes will then be used instead of `updates` when creating the record).
          #
          # ```
          # person = Person.update_or_create(
          #   updates: {first_name: "Bob"},
          #   defaults: {first_name: "Bob", active: true},
          #   first_name: "John",
          #   last_name: "Doe"
          # )
          # ```
          #
          # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
          # exception if multiple records match the specified set of filters.
          def update_or_create(
            *,
            updates : Hash | NamedTuple,
            defaults : Hash | NamedTuple | Nil = nil,
            **kwargs,
          )
            arguments = kwargs.merge({updates: updates, defaults: defaults})
            default_queryset.update_or_create(**arguments)
          end

          # Returns a queryset that will be evaluated using the specified database.
          #
          # A valid database alias must be used here (it must correspond to an ID of a database configured in the
          # project settings). If the passed database alias doesn't correspond to any defined connections, a
          # `Marten::DB::Errors::UnknownConnection` error will be raised.
          def using(db : Nil | String | Symbol)
            all.using(db)
          end
        end

        # Allows to define a default scope for the model query set.
        #
        # The default scope is a set of filters that will be applied to all the queries performed on the model. For
        # example:
        #
        # ```
        # class Post < Marten::Model
        #   field :id, :big_int, primary_key: true, auto: true
        #   field :title, :string, max_size: 255
        #   field :is_published, :bool, default: false
        #
        #   default_scope { filter(is_published: true) }
        # end
        # ```
        macro default_scope
          {% MODEL_SCOPES[:default] = yield %}
        end

        # Allows to define a custom scope for the model query set.
        #
        # Custom scopes allow to define reusable query sets that can be used to filter records in a specific way. For
        # example:
        #
        # ```
        # class Post < Marten::Model
        #   field :id, :big_int, primary_key: true, auto: true
        #   field :title, :string, max_size: 255
        #   field :is_published, :bool, default: false
        #
        #   scope :published { filter(is_published: true) }
        #   scope :unpublished { filter(is_published: false) }
        # end
        #
        # published_posts = Post.published
        # unpublished_posts = Post.unpublished
        #
        # query_set = Post.all
        # published_posts = query_set.published
        # ```
        #
        # Custom scopes can also receive arguments. To do so, required arguments must be defined within the scope block.
        # For example:
        #
        # ```
        # class Post < Marten::Model
        #   field :id, :big_int, primary_key: true, auto: true
        #   field :title, :string, max_size: 255
        #   field :author, :many_to_one, to: Author
        #
        #   scope :by_author_id { |author_id| filter(author_id: author_id) }
        # end
        #
        # posts_by_author = Post.by_author_id(123)
        # ```
        macro scope(name, &block)
          {% MODEL_SCOPES[:custom][name] = block %}
        end

        # :nodoc:
        macro _begin_scoped_querysets_setup
          # :nodoc:
          MODEL_SCOPES = {
            default: nil,
            custom:  {} of Nil => Nil,
          }
        end

        # :nodoc:
        macro _inherit_scoped_querysets
          {% ancestor_model = @type.ancestors.first %}

          {% if ancestor_model.name != "Marten::DB::Model" && ancestor_model.has_constant?("MODEL_SCOPES") %}
            {% for key, value in ancestor_model.constant("MODEL_SCOPES") %}
              {% MODEL_SCOPES[key] = value %}
            {% end %}
          {% end %}
        end

        # :nodoc:
        macro _finish_scoped_querysets_setup
          {% verbatim do %}
            {% if !@type.abstract? %}
              class ::{{ @type }}
                {% if !MODEL_SCOPES[:default].is_a?(NilLiteral) %}
                  def self.default_queryset
                    {{ @type }}::QuerySet.new.{{ MODEL_SCOPES[:default] }}
                  end
                {% end %}

                {% for queryset_id, block in MODEL_SCOPES[:custom] %}
                  def self.{{ queryset_id.id }}{% if !block.args.empty? %}({{ block.args.join(", ").id }}){% end %}
                    default_queryset.{{ block.body }}
                  end
                {% end %}
              end

              class ::{{ @type }}::QuerySet < Marten::DB::Query::Set({{ @type }})
                def initialize(
                  @query = Marten::DB::Query::SQL::Query({{ @type }}).new,
                  @prefetched_relations = [] of ::String,
                  @custom_query_sets  = {} of ::String => Marten::DB::Query::Set::Any
                )
                  super(@query, @prefetched_relations, @custom_query_sets)
                end

                {% for queryset_id, block in MODEL_SCOPES[:custom] %}
                  def {{ queryset_id.id }}{% if !block.args.empty? %}({{ block.args.join(", ").id }}){% end %}
                    {{ block.body }}
                  end
                {% end %}

                protected def clone(other_query = nil)
                  ::{{ @type }}::QuerySet.new(
                    other_query.nil? ? @query.clone : other_query.not_nil!,
                    prefetched_relations,
                    custom_query_sets
                  )
                end
              end

              class ::{{ @type }}::RelatedQuerySet < Marten::DB::Query::RelatedSet({{ @type }})
                def initialize(
                  @instance : Marten::DB::Model,
                  @related_field_id : ::String,
                  query : Marten::DB::Query::SQL::Query({{ @type }})? = nil,
                  @assign_related : ::Bool = false
                )
                  super(@instance, @related_field_id, query, @assign_related)
                end

                {% for queryset_id, block in MODEL_SCOPES[:custom] %}
                  def {{ queryset_id.id }}{% if !block.args.empty? %}({{ block.args.join(", ").id }}){% end %}
                    {{ block.body }}
                  end
                {% end %}

                protected def clone(other_query = nil)
                  ::{{ @type }}::RelatedQuerySet.new(
                    instance: @instance,
                    related_field_id: @related_field_id,
                    query: other_query.nil? ? @query.clone : other_query.not_nil!,
                    assign_related: @assign_related
                  )
                end
              end

              class ::{{ @type }}::ManyToManyQuerySet < Marten::DB::Query::ManyToManySet({{ @type }})
                def initialize(
                  @instance : Marten::DB::Model,
                  @field_id : ::String,
                  @through_related_name : ::String,
                  @through_model_from_field_id : ::String,
                  @through_model_to_field_id : ::String,
                  query : Marten::DB::Query::SQL::Query({{ @type }})? = nil
                )
                  super(
                    @instance,
                    @field_id,
                    @through_related_name,
                    @through_model_from_field_id,
                    @through_model_to_field_id,
                    query
                  )
                end

                {% for queryset_id, block in MODEL_SCOPES[:custom] %}
                  def {{ queryset_id.id }}{% if !block.args.empty? %}({{ block.args.join(", ").id }}){% end %}
                    {{ block.body }}
                  end
                {% end %}

                protected def clone(other_query = nil)
                  ::{{ @type }}::ManyToManyQuerySet.new(
                    instance: @instance,
                    field_id: @field_id,
                    through_related_name: @through_related_name,
                    through_model_from_field_id: @through_model_from_field_id,
                    through_model_to_field_id: @through_model_to_field_id,
                    query: other_query.nil? ? @query.clone : other_query.not_nil!
                  )
                end
              end

              class ::{{ @type }}::Paginator < Marten::DB::Query::Paginator({{ @type }})
              end

              class ::{{ @type }}::Page < Marten::DB::Query::Page({{ @type }})
              end
            {% end %}
          {% end %}
        end

        # :nodoc:
        @prefetched_records_cache : Hash(String, Array(Model))?

        protected def initialize_prefetched_records_cache
          @prefetched_records_cache = {} of String => Array(Model)
        end

        protected def prefetched_records_cache
          @prefetched_records_cache.not_nil!
        end

        protected def prefetched_records_cache_initialized?
          !@prefetched_records_cache.nil?
        end
      end
    end
  end
end
