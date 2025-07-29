module Marten
  module DB
    module Query
      # The main query set class.
      #
      # A query set is an object that matches a collection of records in the database. Those objects are matched through
      # the use of optional filters that allow to explicitly query the database based on specific parameters. Query sets
      # also allow to configure how these objects should be returned (for example in which order).
      #
      # The most important characteristic of a query set is that it is lazily evaluated: unless the code that resulted
      # in the creation of the query set explicitly asks for the underlying objects, no actual query is made to the
      # considered database. Querying the database is always deferred to the last possible moment: that is, when the
      # actual records are requested.
      class Set(M)
        # :nodoc:
        module Any; end

        include Enumerable(M)
        include Any

        @result_cache : Array(M)?
        @prefetched_relations = [] of String
        @custom_query_sets : Hash(String, Any) = {} of String => Any

        # :nodoc:
        getter custom_query_sets

        # :nodoc:
        getter query

        # :nodoc:
        getter prefetched_relations

        # :nodoc:
        getter result_cache

        # :nodoc:
        setter prefetched_relations

        def initialize(
          @query = SQL::Query(M).new,
          @prefetched_relations = [] of String,
          @custom_query_sets = {} of String => Any,
        )
        end

        # Returns the record at the given index.
        #
        # If no record can be found at the given index, then an `IndexError` exception is raised.
        def [](index : Int)
          raise_negative_indexes_not_supported if index < 0

          return @result_cache.not_nil![index] unless @result_cache.nil?

          qs = clone

          qs.query.slice(index, 1)
          qs.fetch
          qs.result_cache.not_nil![0]
        end

        # Returns the record at the given index.
        #
        # `nil` is returned if no record can be found at the given index.
        def []?(index : Int)
          self[index]
        rescue IndexError
          nil
        end

        # Returns the records corresponding to the passed range.
        #
        # If no records match the passed range, an `IndexError` exception is raised. If the current query set was
        # already "consumed" (records were retrieved from the database), an array of records will be returned.
        # Otherwise, another sliced query set will be returned.
        def [](range : Range)
          raise_negative_indexes_not_supported if !range.begin.nil? && range.begin.not_nil! < 0
          raise_negative_indexes_not_supported if !range.end.nil? && range.end.not_nil! < 0

          return @result_cache.not_nil![range] unless @result_cache.nil?

          qs = clone

          from = range.begin.nil? ? 0 : range.begin.not_nil!
          size = if range.end.nil?
                   nil
                 else
                   range.excludes_end? ? (range.end.not_nil! - from) : (range.end.not_nil! + 1 - from)
                 end

          qs.query.slice(from, size)

          qs
        end

        # Returns the records corresponding to the passed range.
        #
        # `nil` is returned if no records match the passed range. If the current query set was already "consumed"
        # (records were retrieved from the database), an array of records will be returned. Otherwise, another sliced
        # query set will be returned.
        def []?(range : Range)
          self[range]
        rescue IndexError
          nil
        end

        # Combines the current query set with another one using the AND operator.
        #
        # This method returns a new query set that is the result of combining the current query set with another one
        # using the AND operator. For example:
        #
        # ```
        # query_set_1 = Post.all.filter(title: "Test")
        # query_set_2 = Post.all.filter(is_published: true)
        #
        # combined_query_set = query_set_1 & query_set_2
        # ```
        def &(other : self)
          return other if other.query.is_a?(SQL::EmptyQuery)
          return self if query.is_a?(SQL::EmptyQuery)

          combined = clone
          combined.query.combine(other.query, SQL::PredicateConnector::AND)

          combined
        end

        # Combines the current query set with another one using the OR operator.
        #
        # This method returns a new query set that is the result of combining the current query set with another one
        # using the OR operator. For example:
        #
        # ```
        # query_set_1 = Post.all.filter(title: "Test")
        # query_set_2 = Post.all.filter(is_published: true)
        #
        # combined_query_set = query_set_1 | query_set_2
        # ```
        def |(other : self)
          return other if query.is_a?(SQL::EmptyQuery)
          return self if other.query.is_a?(SQL::EmptyQuery)

          combined = clone
          combined.query.combine(other.query, SQL::PredicateConnector::OR)

          combined
        end

        # Combines the current query set with another one using the XOR operator.
        #
        # This method returns a new query set that is the result of combining the current query set with another one
        # using the XOR operator. For example:
        #
        # ```
        # query_set_1 = Post.all.filter(title: "Test")
        # query_set_2 = Post.all.filter(is_published: true)
        #
        # combined_query_set = query_set_1 ^ query_set_2
        # ```
        def ^(other : self)
          return other if query.is_a?(SQL::EmptyQuery)
          return self if other.query.is_a?(SQL::EmptyQuery)

          combined = clone
          combined.query.combine(other.query, SQL::PredicateConnector::XOR)

          combined
        end

        # :nodoc:
        def accumulate
          raise NotImplementedError.new("#accumulate is not supported for query sets")
        end

        # Returns a cloned version of the current query set matching all records.
        def all
          clone
        end

        # Returns a new query set with the specified annotations.
        #
        # This method returns a new query set with the specified annotations. The annotations are specified using a
        # block where each annotation has to be wrapped using the `annotate` method. For example:
        #
        # ```
        # query_set = Book.all.annotate { count(:authors) }
        # other_query_set = Book.all.annotate do
        #   count(:authors, alias_name: :author_count)
        #   sum(:pages, alias_name: :total_pages)
        # end
        # ```
        #
        # Each of the specified annotations is then available for further use in the query set (in order to filter or
        # order the records). The annotations are also available in retrieved model records via the `#annotations`
        # method, which returns a hash containing the annotations as keys and their values as values.
        def annotate(&)
          expression = Expression::Annotate.new
          with expression yield

          annotate(expression)
        end

        # Returns a new query set with the specified annotations.
        #
        # This method returns a new query set with the specified annotations. The annotations are specified as a
        # `Marten::DB::Query::Expression::Annotate` object.
        def annotate(expression : Expression::Annotate)
          return self if expression.annotations.empty?

          qs = clone

          expression.annotations.each do |ann|
            qs.query.add_annotation(ann)
          end

          qs
        end

        # Returns `true` if the query set matches at least one record, or `false` otherwise. Alias for `#exists?`.
        def any?
          exists?
        end

        # Returns the average of a field for the current query set.
        #
        # This method calculates the average value of the specified field for the considered query set. For example:
        #
        # ```
        # query_set = Product.all
        # query_set.average(:price) # => 25.0
        # ```
        #
        # This will return the average price of all products in the database.
        def average(field : String | Symbol)
          @query.average(field.try(&.to_s))
        end

        # Initializes a new model instance.
        #
        # The new model instance is initialized by using the attributes defined in the `kwargs` double splat argument.
        #
        # ```
        # new_post = Post.all.build(title: "My blog post")
        # ```
        def build(**kwargs)
          build_record(**kwargs)
        end

        # Initializes a new model instance.
        #
        # This method provides the exact same behaviour as `#build` with the ability to define a block that is executed
        # for the new object. This block can be used to directly initialize the new model instance.
        #
        # ```
        # new_post = Post.all.build(title: "My blog post") do |p|
        #   p.complex_attribute = compute_complex_attribute
        # end
        # ```
        def build(**kwargs, &)
          object = build_record(**kwargs)
          yield object
          object
        end

        # Bulk inserts the passed model instances into the database.
        #
        # This method allows to insert multiple model instances into the database in a single query. This can be useful
        # when dealing with large amounts of data that need to be inserted into the database. For example:
        #
        # ```
        # query_set = Post.all
        # query_set.bulk_create(
        #   [
        #     Post.new(title: "First post"),
        #     Post.new(title: "Second post"),
        #     Post.new(title: "Third post"),
        #   ]
        # )
        # ```
        #
        # An optional `batch_size` argument can be passed to this method in order to specify the number of records that
        # should be inserted in a single query. By default, all records are inserted in a single query (except for
        # SQLite databases where the limit of variables in a single query is 999). For example:
        #
        # ```
        # query_set = Post.all
        # query_set.bulk_create(
        #   [
        #     Post.new(title: "First post"),
        #     Post.new(title: "Second post"),
        #     Post.new(title: "Third post"),
        #   ],
        #   batch_size: 2
        # )
        # ```
        def bulk_create(objects : Array(M), batch_size : Int32? = nil)
          if !batch_size.nil? && batch_size < 1
            raise ArgumentError.new("Batch size must be greater than 1")
          end

          return objects if objects.empty?

          # Check that objects are not descendants of concrete models (multi table inheritance).
          if !M.parent_models.empty?
            raise Errors::UnmetQuerySetCondition.new(
              "Bulk creation is not supported for multi table inherited model records"
            )
          end

          query.connection.transaction do
            objects_with_pk, objects_without_pk = objects.partition(&.pk?)

            if !objects_with_pk.empty?
              perform_batched_insert(objects_with_pk, batch_size)
            end

            if !objects_without_pk.empty?
              inserted_pks = perform_batched_insert(objects_without_pk, batch_size)

              if !inserted_pks.empty?
                objects_without_pk.zip(inserted_pks).each do |object, pk|
                  object.pk = pk.as?(Field::Any)
                end
              end
            end
          end

          # Mark all objects as persisted.
          objects.each(&.new_record=(false))

          objects
        end

        # Returns the number of records that are targeted by the current query set.
        def count(field : String | Symbol | Nil = nil)
          @result_cache.nil? || !field.nil? ? @query.count(field.try(&.to_s)) : @result_cache.not_nil!.size
        end

        # Creates a model instance and saves it to the database if it is valid.
        #
        # The new model instance is initialized by using the attributes defined in the `kwargs` double splat argument.
        # Regardless of whether it is valid or not (and thus persisted to the database or not), the initialized model
        # instance is returned by this method:
        #
        # ```
        # query_set = Post.all
        # query_set.create(title: "My blog post")
        # ```
        def create(**kwargs)
          object = build_record(**kwargs)
          object.save(using: @query.using)
          object
        end

        # Creates a model instance and saves it to the database if it is valid.
        #
        # This method provides the exact same behaviour as `create` with the ability to define a block that is executed
        # for the new object. This block can be used to directly initialize the object before it is persisted to the
        # database:
        #
        # ```
        # query_set = Post.all
        # query_set.create(title: "My blog post") do |post|
        #   post.complex_attribute = compute_complex_attribute
        # end
        # ```
        def create(**kwargs, &)
          object = build_record(**kwargs)
          yield object
          object.save(using: @query.using)
          object
        end

        # Creates a model instance and saves it to the database if it is valid.
        #
        # The model instance is initialized using the attributes defined in the `kwargs` double splat argument. If the
        # model instance is valid, it is persisted to the database ; otherwise a `Marten::DB::Errors::InvalidRecord`
        # exception is raised.
        #
        # ```
        # query_set = Post.all
        # query_set.create!(title: "My blog post")
        # ```
        def create!(**kwargs)
          object = build_record(**kwargs)
          object.save!(using: @query.using)
          object
        end

        # Creates a model instance and saves it to the database if it is valid.
        #
        # This method provides the exact same behaviour as `create!` with the ability to define a block that is executed
        # for the new object. This block can be used to directly initialize the object before it is persisted to the
        # database:
        #
        # ```
        # query_set = Post.all
        # query_set.create!(title: "My blog post") do |post|
        #   post.complex_attribute = compute_complex_attribute
        # end
        # ```
        def create!(**kwargs, &)
          object = build_record(**kwargs)
          yield object
          object.save!(using: @query.using)
          object
        end

        # Deletes the records corresponding to the current query set and returns the number of deleted records.
        #
        # By default, related objects will be deleted by following the deletion strategy defined in each foreign key
        # field if applicable, unless the `raw` argument is set to `true`.
        #
        # When the `raw` argument is set to `true`, a raw SQL delete statement will be used to delete all the records
        # matching the currently applied filters. Note that using this option could cause errors if the underlying
        # database enforces referential integrity.
        #
        # Moreover, it is important to note that using `raw: true` won't delete parent records if considered query set
        # is targeting model records that make use of multi table inheritance.
        def delete(raw : Bool = false) : Int64
          raise Errors::UnmetQuerySetCondition.new("Delete with sliced queries is not supported") if query.sliced?
          raise Errors::UnmetQuerySetCondition.new("Delete with joins is not supported") if query.joins?

          qs = clone

          deleted_count = if raw
                            qs.query.raw_delete
                          else
                            deletion = Deletion::Runner.new(qs.query.connection)
                            deletion.add(qs)
                            deletion.execute
                          end

          reset_result_cache

          deleted_count
        end

        # Returns a new query set that will use SELECT DISTINCT in its query.
        #
        # By doing so it is possible to eliminate any duplicated row in the query set results:
        #
        # ```
        # query_set = Post.all.distinct
        # ```
        def distinct
          raise Errors::UnmetQuerySetCondition.new("Distinct on sliced queries is not supported") if query.sliced?

          qs = clone
          qs.query.setup_distinct_clause

          qs
        end

        # Returns a new query set that will use SELECT DISTINCT ON in its query
        #
        # By doing so it is possible to eliminate any duplicated row based on the specified fields:
        #
        # ```
        # query_set = Post.all.distinct(:title)
        # ```
        #
        # It should be noted that it is also possible to follow associations of direct related models too by using the
        # double underscores notation(`__`). For example the following query will select distinct records based on a
        # joined "author" attribute:
        #
        # ```
        # query_set = Post.all.distinct(:author__name)
        # ```
        def distinct(*fields : String | Symbol)
          raise Errors::UnmetQuerySetCondition.new("Distinct on sliced queries is not supported") if query.sliced?

          qs = clone
          qs.query.setup_distinct_clause(fields.map(&.to_s).to_a)

          qs
        end

        # Allows to iterate over the records that are targeted by the current query set.
        #
        # This method can be used to define a block that iterates over the records that are targeted by a query set:
        #
        # ```
        # Post.all.each do |post|
        #   # Do something
        # end
        # ```
        def each(&)
          fetch if @result_cache.nil?
          @result_cache.not_nil!.each do |r|
            yield r
          end
        end

        # Returns a query set whose records do not match the given set of filters.
        #
        # This method returns a `Marten::DB::Query::Set` object. The filters passed to this method method must be
        # specified using the predicate format:
        #
        # ```
        # query_set = Post.all
        # query_set.exclude(title: "Test")
        # query_set.exclude(title__startswith: "A")
        # ```
        #
        # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
        def exclude(**kwargs)
          exclude(Node.new(**kwargs))
        end

        # Returns a query set whose records do not match the given set of advanced filters.
        #
        # This method returns a `Marten::DB::Query::Set` object and allows to define complex database queries involving
        # **AND** and **OR** operators. It yields a block where each filter has to be wrapped using a `q(...)`
        # expression. These expressions can then be used to build complex queries such as:
        #
        # ```
        # query_set = Post.all
        # query_set.exclude { (q(name: "Foo") | q(name: "Bar")) & q(is_published: True) }
        # ```
        def exclude(&)
          expr = Expression::Filter.new
          query : Node = with expr yield
          exclude(query)
        end

        # Returns a query set whose records do not match the given query node object.
        def exclude(query_node : Node)
          add_query_node(-query_node)
        end

        # Returns `true` if the current query set matches at least one record, or `false` otherwise.
        def exists?
          @result_cache.nil? ? @query.exists? : !@result_cache.not_nil!.empty?
        end

        # Returns `true` if the query set corresponding to the specified filters matches at least one record.
        #
        # This method returns `true` if the filters passed to this method match at least one record. These filters must
        # be specified using the predicate format:
        #
        # ```
        # query_set = Post.all
        # query_set.exists?(title: "Test")
        # query_set.exists?(title__startswith: "A")
        # ```
        #
        # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
        def exists?(**kwargs)
          filter(Node.new(**kwargs)).exists?
        end

        # Returns `true` if the query set corresponding to the specified advanced filters matches at least one record.
        #
        # This method returns a `Bool` object and allows to define complex database queries involving **AND** and **OR**
        # operators. It yields a block where each filter has to be wrapped using a `q(...)` expression. These
        # expressions can then be used to build complex queries such as:
        #
        # ```
        # query_set = Post.all
        # query_set.exists? { (q(name: "Foo") | q(name: "Bar")) & q(is_published: true) }
        # ```
        def exists?(&)
          expr = Expression::Filter.new
          query : Node = with expr yield
          filter(query).exists?
        end

        # Returns `true` if the a query set filtered with the given query node object matches at least one record.
        # ```
        # query_set = Post.all
        # query_set.exists?(Marten::DB::Query::Node.new(name__startswith: "Fr"))
        # ```
        def exists?(query_node : Node)
          filter(query_node).exists?
        end

        # Returns a query set matching a specific set of filters.
        #
        # This method returns a `Marten::DB::Query::Set` object. The filters passed to this method method must be
        # specified using the predicate format:
        #
        # ```
        # query_set = Post.all
        # query_set.filter(title: "Test")
        # query_set.filter(title__startswith: "A")
        # ```
        #
        # If multiple filters are specified, they will be joined using an **AND** operator at the SQL level.
        def filter(**kwargs)
          filter(Node.new(**kwargs))
        end

        # Returns a query set matching a specific set of advanced filters.
        #
        # This method returns a `Marten::DB::Query::Set` object and allows to define complex database queries involving
        # **AND** and **OR** operators. It yields a block where each filter has to be wrapped using a `q(...)`
        # expression. These expressions can then be used to build complex queries such as:
        #
        # ```
        # query_set = Post.all
        # query_set.filter { (q(name: "Foo") | q(name: "Bar")) & q(is_published: true) }
        # ```
        def filter(&)
          expr = Expression::Filter.new
          query : Node = with expr yield
          filter(query)
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
          raise_empty_raw_predicate if raw_predicate.empty?
          add_query_node(Node.new(raw_predicate))
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
          filter(raw_predicate, args.to_a)
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
          filter(raw_predicate, kwargs.to_h)
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
          raise_empty_raw_predicate if raw_predicate.empty?

          raw_params = [] of ::DB::Any
          raw_params += params

          add_query_node(Node.new(raw_predicate: raw_predicate, params: raw_params))
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
          raise_empty_raw_predicate if raw_predicate.empty?

          raw_params = {} of String => ::DB::Any
          params.each { |k, v| raw_params[k.to_s] = v }

          add_query_node(Node.new(raw_predicate: raw_predicate, params: raw_params))
        end

        # Returns a query set whose records match the given query node.
        def filter(query_node : Node)
          add_query_node(query_node)
        end

        # Returns the first record that is matched by the query set, or `nil` if no records are found.
        def first
          (query.ordered? ? self : order(Constants::PRIMARY_KEY_ALIAS))[0]?
        end

        # Returns the first record that is matched by the query set, or raises a `NilAssertionError` error otherwise.
        def first!
          first.not_nil!
        end

        # Returns the model instance matching the given set of filters.
        #
        # Model fields such as primary keys or fields with a unique constraint should be used here in order to retrieve
        # a specific record:
        #
        # ```
        # query_set = Post.all
        # post_1 = query_set.get(id: 123)
        # post_2 = query_set.get(id: 456, is_published: false)
        # ```
        #
        # If the specified set of filters doesn't match any records, the returned value will be `nil`.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get(**kwargs)
          get(Node.new(**kwargs))
        end

        # Returns the model instance matching a specific set of advanced filters.
        #
        # Model fields such as primary keys or fields with a unique constraint should be used here in order to retrieve
        # a specific record:
        #
        # ```
        # query_set = Post.all
        # post_1 = query_set.get { q(id: 123) }
        # post_2 = query_set.get { q(id: 456, is_published: false) }
        # ```
        #
        # If the specified set of filters doesn't match any records, the returned value will be `nil`.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get(&)
          expr = Expression::Filter.new
          query : Node = with expr yield
          get(query)
        end

        # Returns the model instance matching a specific query node object, or `nil` if no record is found.
        def get(query_node : Node)
          get!(query_node)
        rescue Errors::RecordNotFound
          nil
        end

        # Returns the model instance matching the given raw SQL predicate.
        #
        # This method allows retrieving a record based on a custom SQL predicate without parameters.
        # It returns `nil` if no record matches the predicate.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get("is_active = true")
        # ```
        def get(raw_predicate : String)
          raise_empty_raw_predicate if raw_predicate.empty?
          get(Node.new(raw_predicate))
        end

        # Returns the model instance matching the given raw SQL predicate with positional arguments.
        #
        # This method allows retrieving a record based on a custom SQL predicate with positional arguments.
        # It returns `nil` if no record matches the predicate.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get("name=?", "crystal")
        # ```
        def get(raw_predicate : String, *args)
          get(raw_predicate, args.to_a)
        end

        # Returns the model instance matching the given raw SQL predicate with positional parameters.
        #
        # This method allows retrieving a record based on a custom SQL predicate using an array of parameters.
        # It returns `nil` if no record matches the predicate.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get("name=? AND is_active=?", ["crystal", true])
        # ```
        def get(raw_predicate : String, params : Array)
          raise_empty_raw_predicate if raw_predicate.empty?

          raw_params = [] of ::DB::Any
          raw_params += params

          get(Node.new(raw_predicate: raw_predicate, params: raw_params))
        end

        # Returns the model instance matching the given raw SQL predicate with named parameters.
        #
        # This method allows retrieving a record based on a custom SQL predicate using named parameters.
        # It returns `nil` if no record matches the predicate.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get("name=:name AND is_active=:active", name: "crystal", active: true)
        # ```
        def get(raw_predicate : String, **kwargs)
          get(raw_predicate, kwargs.to_h)
        end

        # Returns the model instance matching the given raw SQL predicate with a named parameters hash.
        #
        # This method allows retrieving a record based on a custom SQL predicate using a hash of named parameters.
        # It returns `nil` if no record matches the predicate.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get("name=:name", {name: "crystal"})
        # ```
        def get(raw_predicate : String, params : Hash | NamedTuple)
          raise_empty_raw_predicate if raw_predicate.empty?

          raw_params = {} of String => ::DB::Any
          params.each { |k, v| raw_params[k.to_s] = v }

          get(Node.new(raw_predicate: raw_predicate, params: raw_params))
        end

        # Returns the model instance matching the given set of filters.
        #
        # Model fields such as primary keys or fields with a unique constraint should be used here in order to retrieve
        # a specific record:
        #
        # ```
        # query_set = Post.all
        # post_1 = query_set.get!(id: 123)
        # post_2 = query_set.get!(id: 456, is_published: false)
        # ```
        #
        # If the specified set of filters doesn't match any records, a `Marten::DB::Errors::RecordNotFound` exception
        # will be raised.
        #
        # In order to ensure data consistency, this method will also raise a
        # `Marten::DB::Errors::MultipleRecordsFound` exception if multiple records match the specified set of filters.
        def get!(**kwargs)
          get!(Node.new(**kwargs))
        end

        # Returns the model instance matching a specific set of advanced filters.
        #
        # Model fields such as primary keys or fields with a unique constraint should be used here in order to retrieve
        # a specific record:
        #
        # ```
        # query_set = Post.all
        # post_1 = query_set.get! { q(id: 123) }
        # post_2 = query_set.get! { q(id: 456, is_published: false) }
        # ```
        #
        # If the specified set of filters doesn't match any records, a `Marten::DB::Errors::RecordNotFound` exception
        # will be raised.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get!(&)
          expr = Expression::Filter.new
          query : Node = with expr yield
          get!(query)
        end

        # Returns the model instance matching a specific query node object, or raise an error otherwise.
        def get!(query_node : Node)
          results = filter(query_node)[..GET_RESULTS_LIMIT].to_a
          return results.first if results.size == 1
          raise Errors::RecordNotFound.new("#{M.name} query didn't return any results") if results.empty?
          raise Errors::MultipleRecordsFound.new("Multiple records (#{results.size}) found for get query")
        end

        # Returns the model instance matching the given raw SQL predicate, raising an error if not found.
        #
        # This method allows retrieving a record based on a custom SQL predicate without parameters.
        # If no record matches the predicate, a `RecordNotFound` exception is raised.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get!("is_active = true")
        # ```
        def get!(raw_predicate : String)
          raise_empty_raw_predicate if raw_predicate.empty?
          get!(Node.new(raw_predicate))
        end

        # Returns the model instance matching the given raw SQL predicate with positional arguments, raising an
        # error if not found.
        #
        # This method allows retrieving a record based on a custom SQL predicate with positional arguments.
        # If no record matches the predicate, a `RecordNotFound` exception is raised.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get!("name=?", "crystal")
        # ```
        def get!(raw_predicate : String, *args)
          get!(raw_predicate, args.to_a)
        end

        # Returns the model instance matching the given raw SQL predicate with positional parameters, raising an
        # error if not found.
        #
        # This method allows retrieving a record based on a custom SQL predicate using an array of parameters.
        # If no record matches the predicate, a `RecordNotFound` exception is raised.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get!("name=? AND is_active=?", ["crystal", true])
        # ```
        def get!(raw_predicate : String, params : Array)
          raise_empty_raw_predicate if raw_predicate.empty?

          raw_params = [] of ::DB::Any
          raw_params += params

          get!(Node.new(raw_predicate: raw_predicate, params: raw_params))
        end

        # Returns the model instance matching the given raw SQL predicate with named parameters, raising an
        # error if not found.
        #
        # This method allows retrieving a record based on a custom SQL predicate using named parameters.
        # If no record matches the predicate, a `RecordNotFound` exception is raised.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get!("name=:name AND is_active=:active", name: "crystal", active: true)
        # ```
        def get!(raw_predicate : String, **kwargs)
          get!(raw_predicate, kwargs.to_h)
        end

        # Returns the model instance matching the given raw SQL predicate with a named parameters hash, raising an
        # error if not found.
        #
        # This method allows retrieving a record based on a custom SQL predicate using a hash of named parameters.
        # If no record matches the predicate, a `RecordNotFound` exception is raised.
        #
        # For example:
        #
        # ```
        # tag = Tag.all.get!("name=:name", {name: "crystal"})
        # ```
        def get!(raw_predicate : String, params : Hash | NamedTuple)
          raise_empty_raw_predicate if raw_predicate.empty?

          raw_params = {} of String => ::DB::Any
          params.each { |k, v| raw_params[k.to_s] = v }

          get!(Node.new(raw_predicate: raw_predicate, params: raw_params))
        end

        # Returns the model record matching the given set of filters or create a new one if no one is found.
        #
        # Model fields that uniquely identify a record should be used here. For example:
        #
        # ```
        # tag = Tag.all.get_or_create(label: "crystal")
        # ```
        #
        # When no record is found, the new model instance is initialized by using the attributes defined in the `kwargs`
        # double splat argument. Regardless of whether it is valid or not (and thus persisted to the database or not),
        # the initialized model instance is returned by this method.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get_or_create(**kwargs)
          get!(Node.new(**kwargs))
        rescue Errors::RecordNotFound
          create(**kwargs)
        end

        # Returns the model record matching the given set of filters or create a new one if no one is found.
        #
        # Model fields that uniquely identify a record should be used here. The provided block can be used to initialize
        # the model instance to create (in case no record is found). For example:
        #
        # ```
        # tag = Tag.all.get_or_create(label: "crystal") do |new_tag|
        #   new_tag.active = false
        # end
        # ```
        #
        # When no record is found, the new model instance is initialized by using the attributes defined in the `kwargs`
        # double splat argument. Regardless of whether it is valid or not (and thus persisted to the database or not),
        # the initialized model instance is returned by this method.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get_or_create(**kwargs, &)
          get!(Node.new(**kwargs))
        rescue Errors::RecordNotFound
          create(**kwargs) { |r| yield r }
        end

        # Returns the model record matching the given set of filters or create a new one if no one is found.
        #
        # Model fields that uniquely identify a record should be used here. For example:
        #
        # ```
        # tag = Tag.all.get_or_create!(label: "crystal")
        # ```
        #
        # When no record is found, the new model instance is initialized by using the attributes defined in the `kwargs`
        # double splat argument. If the new model instance is valid, it is persisted to the database ; otherwise a
        # `Marten::DB::Errors::InvalidRecord` exception is raised.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get_or_create!(**kwargs)
          get!(Node.new(**kwargs))
        rescue Errors::RecordNotFound
          create!(**kwargs)
        end

        # Returns the model record matching the given set of filters or create a new one if no one is found.
        #
        # Model fields that uniquely identify a record should be used here. The provided block can be used to initialize
        # the model instance to create (in case no record is found). For example:
        #
        # ```
        # tag = Tag.all.get_or_create!(label: "crystal") do |new_tag|
        #   new_tag.active = false
        # end
        # ```
        #
        # When no record is found, the new model instance is initialized by using the attributes defined in the `kwargs`
        # double splat argument. If the new model instance is valid, it is persisted to the database ; otherwise a
        # `Marten::DB::Errors::InvalidRecord` exception is raised.
        #
        # In order to ensure data consistency, this method will raise a `Marten::DB::Errors::MultipleRecordsFound`
        # exception if multiple records match the specified set of filters.
        def get_or_create!(**kwargs, &)
          get!(Node.new(**kwargs))
        rescue Errors::RecordNotFound
          create!(**kwargs) { |r| yield r }
        end

        # Returns `true` if a specific model record is included in the query set.
        def includes?(value : M)
          raise Errors::UnmetQuerySetCondition.new("#{value} is not persisted") unless value.persisted?

          if @result_cache.nil?
            filter(Node.new({Constants::PRIMARY_KEY_ALIAS => value.pk})).exists?
          else
            @result_cache.not_nil!.includes?(value)
          end
        end

        # Appends a string representation of the query set to the passed `io`.
        def inspect(io)
          results = self[...INSPECT_RESULTS_LIMIT + 1].to_a
          io << "<#{self.class.name} ["
          io << "#{results[...INSPECT_RESULTS_LIMIT].join(", ", &.inspect)}"
          io << ", ...(remaining truncated)..." if results.size > INSPECT_RESULTS_LIMIT
          io << "]>"
        end

        # :nodoc:
        def join
          raise Errors::UnmetQuerySetCondition.new("Relations must be specified when joining")
        end

        # Returns a queryset whose specified `relations` are "followed" and joined to each result.
        #
        # When using `#join`, the specified relationships will be followed and each record returned by the queryset will
        # have the corresponding related objects already selected and populated. Using `#join` can result in performance
        # improvements since it can help reduce the number of SQL queries, as illustrated by the following example:
        #
        # ```
        # query_set = Post.all
        #
        # p1 = query_set.get(id: 1)
        # puts p1.author # hits the database to retrieve the related "author"
        #
        # p2 = query_set.join(:author).get(id: 1)
        # puts p2.author # doesn't hit the database since the related "author" was already selected
        # ```
        #
        # It should be noted that it is also possible to follow foreign keys of direct related models too by using the
        # double underscores notation(`__`). For example the following query will select the joined "author" and its
        # associated "profile":
        #
        # ```
        # query_set = Post.all
        # query_set.join(:author__profile)
        # ```
        def join(*relations : String | Symbol)
          qs = clone
          relations.each do |relation|
            qs.query.add_selected_join(relation.to_s)
          end
          qs
        end

        # Returns the last record that is matched by the query set, or `nil` if no records are found.
        def last
          (query.ordered? ? reverse : order("-#{Constants::PRIMARY_KEY_ALIAS}"))[0]?
        end

        # Returns the last record that is matched by the query set, or raises a `NilAssertionError` error otherwise.
        def last!
          last.not_nil!
        end

        # Returns the maximum value of a field for the current query set.
        #
        # Finds the smallest value within the specified field for the records targeted by the query set. For example:
        #
        # ```
        # products = Product.where(category: "Electronics")
        # lowest_price = products.maximum(:price)
        # ```
        #
        # This would identify the highest-priced product within the "Electronics" category.
        def maximum(field : String | Symbol)
          @query.maximum(field.try(&.to_s))
        end

        # Returns the minimum value of a field for the current query set.
        #
        # Finds the smallest value within the specified field for the records targeted by the query set. For example:
        #
        # ```
        # products = Product.where(category: "Electronics")
        # lowest_price = products.minimum(:price)
        # ```
        #
        # This would identify the lowest-priced product within the "Electronics" category.
        def minimum(field : String | Symbol)
          @query.minimum(field.try(&.to_s))
        end

        # Returns the model class associated with the query set.
        def model
          M
        end

        # Returns a queryset that will always return an empty array of record, without querying the database.
        #
        # Once this method is used, any subsequent method call (such as extra filters) will continue returning an empty
        # array of records.
        def none
          clone(query.to_empty)
        end

        # Allows to specify the ordering in which records should be returned when evaluating the query set.
        #
        # Multiple fields can be specified in order to define the final ordering. For example:
        #
        # ```
        # query_set = Post.all
        # query_set.order("-published_at", "title")
        # ```
        #
        # In the above example, records would be ordered by descending publication date, and then by title (ascending).
        def order(*fields : String | Symbol)
          order(fields.to_a)
        end

        # Allows to specify the ordering in which records should be returned when evaluating the query set.
        #
        # Multiple fields can be specified in order to define the final ordering. For example:
        #
        # ```
        # query_set = Post.all
        # query_set.order(["-published_at", "title"])
        # ```
        #
        # In the above example, records would be ordered by descending publication date, and then by title (ascending).
        def order(fields : Array(String | Symbol))
          qs = clone
          qs.query.order(fields.map(&.to_s))
          qs
        end

        # Returns a queryset that will automatically prefetch in a single batch the records for the specified relations.
        #
        # When using `#prefetch`, the records corresponding to the specified relationships will be prefetched in single
        # batches and each record returned by the queryset will have the corresponding related objects already selected
        # and populated. Using `#prefetch` can result in performance improvements since it can help reduce the number of
        # SQL queries, as illustrated by the following example:
        #
        # ```
        # posts_1 = Post.all.to_a
        # puts posts_1[0].tags.to_a # hits the database to retrieve the related "tags" (many-to-many relation)
        #
        # posts_2 = Post.all.prefetch(:tags).to_a
        # puts posts_2[0].tags # doesn't hit the database since the related "tags" relation was already prefetched
        # ```
        #
        # It should be noted that it is also possible to follow relations and reverse relations too by using the double
        # underscores notation(`__`). For example the following query will prefetch the "author" relation and then the
        # "favorite tags" relation of the author records:
        #
        # ```
        # query_set = Post.all
        # query_set.prefetch(:author__favorite_tags)
        # ```
        #
        # Finally, it is worth mentioning that multiple relations can be specified to `#prefetch`. For example:
        #
        # ```
        # Author.all.prefetch(:books__genres, :publisher)
        # ```
        def prefetch(*relations : String | Symbol)
          qs = clone
          qs.prefetched_relations += relations.map(&.to_s).to_a
          qs
        end

        # Returns a queryset that will automatically prefetch in a single batch the records for the specified relation,
        # with a custom queryset to control how the related records are queried. The prefetched records will be
        # populated on the returned queryset. Using this method can result in performance improvements by reducing
        # the number of SQL queries, as illustrated by the following example:
        #
        # ```
        # # Prefetching with a custom queryset
        # posts = Post.all.prefetch(:tags, query_set: Tag.order(:name)).to_a
        # puts posts[0].tags # Prefetched with custom ordering
        # ```
        #
        # It should be noted that this method enforces type-checking for the custom queryset to ensure its model matches
        # the relation being prefetched. If a type mismatch is detected, a `Marten::DB::Errors::UnmetQuerySetCondition`
        # exception will be raised. For example:
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
        def prefetch(relation_name : String | Symbol, query_set : Any)
          relation_name = relation_name.to_s

          qs = clone
          qs.prefetched_relations << relation_name
          qs.custom_query_sets[relation_name] = query_set
          qs
        end

        # :nodoc:
        def product
          raise NotImplementedError.new("#product is not supported for query sets")
        end

        # Returns a paginator that can be used to paginate the current query set.
        #
        # This method returns a `Marten::DB::Query::Paginator` object, which can then be used to retrieve specific
        # pages.
        def paginator(page_size : Int)
          Paginator(M).new(self, page_size.to_i32)
        end

        # Returns specific column values for a single record without actually loading it.
        #
        # This method allows to easily select specific column values for a single record from the current query set.
        # This allows retrieving specific column values without actually loading the entire record, and as such this is
        # most useful for query sets that have been narrowed down to match a single record. The method returns an array
        # containing the requested column values, or `nil` if no record was matched by the current query set. For
        # example:
        #
        # ```
        # Post.filter(pk: 1).pick("title", "published")
        # # => ["First article", true]
        # ```
        def pick(*fields : String | Symbol) : Array(Field::Any)?
          pick(fields.to_a)
        end

        # Returns specific column values for a single record without actually loading it.
        #
        # This method allows to easily select specific column values for a single record from the current query set.
        # This allows retrieving specific column values without actually loading the entire record, and as such this is
        # most useful for query sets that have been narrowed down to match a single record. The method returns an array
        # containing the requested column values, or `nil` if no record was matched by the current query set. For
        # example:
        #
        # ```
        # Post.filter(pk: 1).pick(["title", "published"])
        # # => ["First article", true]
        # ```
        def pick(fields : Array(String | Symbol)) : Array(Field::Any)?
          qs = clone
          qs.query.slice(0, 1)
          qs.pluck(fields.map(&.to_s)).first?
        end

        # Returns specific column values for a single record without actually loading it.
        #
        # This method allows to easily select specific column values for a single record from the current query set.
        # This allows retrieving specific column values without actually loading the entire record, and as such this is
        # most useful for query sets that have been narrowed down to match a single record. The method returns an array
        # containing the requested column values, or raises `NilAssertionError` if no record was matched by the current
        # query set. For example:
        #
        # ```
        # Post.filter(pk: 1).pick!("title", "published")
        # # => ["First article", true]
        # ```
        def pick!(*fields : String | Symbol) : Array(Field::Any)
          pick!(fields.to_a)
        end

        # Returns specific column values for a single record without actually loading it.
        #
        # This method allows to easily select specific column values for a single record from the current query set.
        # This allows retrieving specific column values without actually loading the entire record, and as such this is
        # most useful for query sets that have been narrowed down to match a single record. The method returns an array
        # containing the requested column values, or raises `NilAssertionError` if no record was matched by the current
        # query set. For example:
        #
        # ```
        # Post.filter(pk: 1).pick!(["title", "published"])
        # # => ["First article", true]
        # ```
        def pick!(fields : Array(String | Symbol)) : Array(Field::Any)
          pick(fields).not_nil!
        end

        # Returns the primary key values of the considered model records targeted by the current query set.
        #
        # This method returns an array containing the primary key values of the model records that are targeted by the
        # current query set. For example:
        #
        # ```
        # Post.all.pks # => [1, 2, 3]
        # ```
        def pks
          pluck(:pk).map(&.first)
        end

        # Returns specific column values without loading entire record objects.
        #
        # This method allows to easily select specific column values from the current query set. This allows retrieving
        # specific column values without actually loading entire records. The method returns an array containing one
        # array with the actual column values for each record targeted by the query set. For example:
        #
        # ```
        # Post.all.pluck("title", "published")
        # # => [["First article", true], ["Upcoming article", false]]
        # ```
        def pluck(*fields : String | Symbol) : Array(Array(Field::Any))
          pluck(fields.to_a)
        end

        # Returns specific column values without loading entire record objects.
        #
        # This method allows to easily select specific column values from the current query set. This allows retrieving
        # specific column values without actually loading entire records. The method returns an array containing one
        # array with the actual column values for each record targeted by the query set. For example:
        #
        # ```
        # Post.all.pluck(["title", "published"])
        # # => [["First article", true], ["Upcoming article", false]]
        # ```
        def pluck(fields : Array(String | Symbol)) : Array(Array(Field::Any))
          clone.query.pluck(fields.map(&.to_s))
        end

        # Returns a raw query set for the passed SQL query and optional positional parameters.
        #
        # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
        # matched by the passed SQL query. For example:
        #
        # ```
        # Article.all.raw("SELECT * FROM articles")
        # ```
        #
        # Additional positional parameters can also be specified if the query needs to be parameterized. For example:
        #
        # ```
        # Article.all.raw("SELECT * FROM articles WHERE title = ? and created_at > ?", "Hello World!", "2022-10-30")
        # ```
        def raw(query : String, *args)
          raw(query, args.to_a)
        end

        # Returns a raw query set for the passed SQL query and optional named parameters.
        #
        # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
        # matched by the passed SQL query. For example:
        #
        # ```
        # Article.all.raw("SELECT * FROM articles")
        # ```
        #
        # Additional named parameters can also be specified if the query needs to be parameterized. For example:
        #
        # ```
        # Article.all.raw(
        #   "SELECT * FROM articles WHERE title = :title and created_at > :created_at",
        #   title: "Hello World!",
        #   created_at: "2022-10-30"
        # )
        # ```
        def raw(query : String, **kwargs)
          raw(query, kwargs.to_h)
        end

        # Returns a raw query set for the passed SQL query and positional parameters.
        #
        # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
        # matched by the passed SQL query and associated positional parameters. For example:
        #
        # ```
        # Article.all.raw("SELECT * FROM articles WHERE title = ? and created_at > ?", ["Hello World!", "2022-10-30"])
        # ```
        def raw(query : String, params : Array)
          raw_params = [] of ::DB::Any
          raw_params += params

          RawSet(M).new(query: query, params: raw_params, using: @query.using)
        end

        # Returns a raw query set for the passed SQL query and named parameters.
        #
        # This method returns a `Marten::DB::Query::RawSet` object, which allows to iterate over the model records
        # matched by the passed SQL query and associated named parameters. For example:
        #
        # ```
        # Article.all.raw(
        #   "SELECT * FROM articles WHERE title = :title and created_at > :created_at",
        #   {
        #     title:      "Hello World!",
        #     created_at: "2022-10-30",
        #   }
        # )
        # ```
        def raw(query : String, params : Hash | NamedTuple)
          raw_params = {} of String => ::DB::Any
          params.each { |k, v| raw_params[k.to_s] = v }

          RawSet(M).new(query: query, params: raw_params, using: @query.using)
        end

        # Allows to reverse the order of the current query set.
        def reverse
          qs = clone
          qs.query.default_ordering = !@query.default_ordering?
          qs
        end

        # Returns the number of records that are targeted by the current query set.
        def size
          count
        end

        # :nodoc:
        def sum
          raise NotImplementedError.new("#sum is not supported for query sets")
        end

        # Returns the sum of a field for the current query set.
        #
        # Calculates the total sum of values within the specified field for the records
        # included in the query set. For example:
        #
        # ```
        # order_items = OrderItem.filter(order_id: 123)
        # total_price = order_items.sum(:price)
        # ```
        #
        # This would calculate the total cost of all items within order number 123.
        def sum(field : String | Symbol)
          @query.sum(field.to_s)
        end

        # :nodoc:
        def to_h
          raise NotImplementedError.new("#to_h is not supported for query sets")
        end

        # Appends a string representation of the query set to the passed `io`.
        def to_s(io)
          inspect(io)
        end

        # Returns the SQL representation of the current query set.
        def to_sql : String
          @query.to_sql
        end

        # Updates all the records matched by the current query set with the passed values.
        #
        # This method allows to update all the records that are matched by the current query set with a hash or a named
        # tuple of values. It returns the number of records that were updated:
        #
        # ```
        # query_set = Post.all
        # query_set.update({"title" => "Updated"})
        # ```
        #
        # It should be noted that this methods results in a regular `UPDATE` SQL statement. As such, the records that
        # are updated through the use of this method won't be validated, and no callbacks will be executed for them
        # either.
        def update(values : Hash | NamedTuple)
          update_hash = Hash(String | Symbol, Field::Any | DB::Model).new
          update_hash.merge!(values.to_h)

          qs = clone
          updated_count = qs.query.update_with(update_hash)

          reset_result_cache

          updated_count
        end

        # Updates all the records matched by the current query set with the passed values.
        #
        # This method allows to update all the records that are matched by the current query set with the values defined
        # in the `kwargs` double splat argument. It returns the number of records that were updated:
        #
        # ```
        # query_set = Post.all
        # query_set.update(title: "Updated")
        # ```
        #
        # It should be noted that this methods results in a regular `UPDATE` SQL statement. As such, the records that
        # are updated through the use of this method won't be validated, and no callbacks will be executed for them
        # either.
        def update(**kwargs)
          update(kwargs.to_h)
        end

        # Allows to define which database alias should be used when evaluating the query set.
        def using(db : Nil | String | Symbol)
          qs = clone
          qs.query.using = db.try(&.to_s)
          qs
        end

        protected def build_record(**kwargs)
          M.new(**kwargs)
        end

        protected def clone(other_query = nil)
          Set(M).new(
            query: other_query.nil? ? @query.clone : other_query.not_nil!,
            prefetched_relations: prefetched_relations,
            custom_query_sets: custom_query_sets
          )
        end

        protected def fetch
          @result_cache = @query.execute
          prefetch_relations if !prefetched_relations.empty?
        end

        protected def assign_cached_records(records : Array(Model)) : Nil
          @result_cache = Array(M).new

          records.each do |record|
            next unless record.is_a?(M)
            @result_cache.not_nil! << record
          end
        end

        protected def unsafe_bulk_create(objects : Array(DB::Model), batch_size : Int32? = nil)
          prepared_objects = [] of M
          objects.each { |o| prepared_objects << o if o.is_a?(M) }

          bulk_create(prepared_objects.as(Array(M)), batch_size)
        end

        private INSPECT_RESULTS_LIMIT = 20
        private GET_RESULTS_LIMIT     = 20

        private def add_query_node(query_node)
          qs = clone
          qs.query.add_query_node(query_node)
          qs
        end

        private def perform_batched_insert(objects : Array(M), batch_size : Int32? = nil)
          max_batch_size = @query.connection.bulk_batch_size(objects.size, M.local_fields.count(&.db_column?))
          effective_batch_size = batch_size.nil? ? max_batch_size : [batch_size, max_batch_size].min

          inserted_pks = Array(::DB::Any).new

          pk_column_to_fetch = M.auto_increment_pk_field? ? M.pk_field.db_column! : nil

          objects.each_slice(effective_batch_size) do |sliced_objects|
            # Ensure all objects' fields are prepared for save before inserting them. This is necessary to ensure that
            # fields like creation timestamp are properly set.
            sliced_objects.each(&.prepare_fields_for_save)
            values_to_insert = sliced_objects.map do |o|
              values = o.local_field_db_values
              values.delete(pk_column_to_fetch) if !pk_column_to_fetch.nil?
              values
            end

            result = @query.connection.bulk_insert(M.db_table, values_to_insert, pk_column_to_fetch)

            if result.is_a?(Array(::DB::Any))
              inserted_pks += result
            end
          end

          inserted_pks
        end

        private def prefetch_relations : Nil
          return if @result_cache.nil? || @result_cache.try(&.empty?)

          prefetcher = Prefetcher.new(
            records: Array(Model).new.concat(@result_cache.not_nil!),
            relations: prefetched_relations,
            using: @query.using,
            custom_query_sets: custom_query_sets,
          )
          prefetcher.execute
        end

        private def raise_empty_raw_predicate
          raise Errors::UnmetQuerySetCondition.new("Raw predicates cannot be empty")
        end

        private def raise_negative_indexes_not_supported
          raise Errors::UnmetQuerySetCondition.new("Negative indexes are not supported")
        end

        private def reset_result_cache
          @result_cache = nil
        end
      end
    end
  end
end
