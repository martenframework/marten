module Marten
  module DB
    abstract class Model
      module Querying
        macro included
          extend Marten::DB::Model::Querying::ClassMethods
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

          # Returns a queryset targetting all the records for the considered model.
          #
          # This method returns a `Marten::DB::Query::Set` object that - if evaluated - will return all the records for
          # the considered model.
          def all
            default_queryset
          end

          # Returns `true` if the model query set matches at least one record or `false` otherwise. Alias of `#exists?`.
          def any?
            exists?
          end

          # Returns the default queryset to use when creating "unfiltered" querysets for the model at hand.
          def default_queryset
            {% begin %}
            {% if @type.abstract? %}
            raise "Records can only be queried from non-abstract model classes"
            {% else %}
            Query::Set({{ @type }}).new
            {% end %}
            {% end %}
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

          # Returns a queryset targetting all the records for the considered model with the specified ordering.
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

          # Returns a queryset targetting all the records for the considered model with the specified ordering.
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

          # Returns a queryset that will be evaluated using the specified database.
          #
          # A valid database alias must be used here (it must correspond to an ID of a database configured in the
          # project settings). If the passed database alias doesn't correspond to any defined connections, a
          # `Marten::DB::Errors::UnknownConnection` error will be raised.
          def using(db : String | Symbol)
            all.using(db)
          end
        end
      end
    end
  end
end
