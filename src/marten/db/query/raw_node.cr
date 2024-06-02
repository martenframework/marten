module Marten
  module DB
    module Query
      class RawNode < Node
        getter statement
        getter params

        def initialize(
          @statement : String,
          @params = [] of ::DB::Any,
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false
        )
          @filters = FilterHash.new
          fill_filters(kwargs)
        end

        def initialize(
          @statement : String,
          @params = [] of ::DB::Any,
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false,
          @filters = FilterHash.new
        )
        end

        def initialize(
          @statement : String,
          @params : Array(::DB::Any) | Hash(String, ::DB::Any),
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false,
          @filters = FilterHash.new
        )
        end

        def ==(other : self)
          (
            (other.statement == @statement) &&
              (other.params == @params) &&
              (other.connector == @connector) &&
              (other.negated == @negated)
          )
        end

        protected def add(other : self, conn : SQL::PredicateConnector)
          return if @children.includes?(other)

          if @connector == conn
            @children << other
          else
            new_child = self.class.new(children: @children, connector: @connector, negated: @negated, filters: @filters)
            @connector = conn
            @children = [new_child, other]
          end
        end

        protected def negate
          @negated = !@negated
        end

        private def combine(other, conn)
          combined = Node.new(connector: conn)
          combined.add(self, conn)
          combined.add(other, conn)
          combined
        end

        private def fill_filters(filters)
          filters.each do |key, value|
            @filters[key.to_s] = case value
                                 when DB::Model, Field::Any
                                   value
                                 when Array
                                   prepare_filter_array(value)
                                 when Set
                                   prepare_filter_array(value.to_a)
                                 else
                                   value.to_s
                                 end
          end
        end

        private def prepare_filter_array(value : Array)
          if value.all?(DB::Model)
            value.each_with_object(Array(DB::Model).new) do |v, arr|
              arr << v if v.is_a?(DB::Model)
            end
          else
            value.each_with_object(Array(Field::Any).new) do |v, arr|
              arr << (v.is_a?(Field::Any) ? v : v.to_s)
            end
          end
        end
      end
    end
  end
end
