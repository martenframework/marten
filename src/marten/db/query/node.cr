module Marten
  module DB
    module Query
      class Node
        alias FilterHash = Hash(String, Field::Any | Array(Field::Any) | DB::Model | Array(DB::Model))

        getter children
        getter connector
        getter filters
        getter negated

        def initialize(
          @children = [] of self,
          @connector = SQL::PredicateConnector::AND,
          @negated = false,
          **kwargs
        )
          @filters = FilterHash.new
          fill_filters(kwargs)
        end

        def initialize(
          filters : Hash | NamedTuple,
          @children = [] of self,
          @connector = SQL::PredicateConnector::AND,
          @negated = false
        )
          @filters = FilterHash.new
          fill_filters(filters)
        end

        def initialize(
          @children : Array(self),
          @connector : SQL::PredicateConnector,
          @negated : Bool,
          @filters : FilterHash
        )
        end

        def ==(other : self)
          (
            (other.filters == @filters) &&
              (other.children == @children) &&
              (other.connector == @connector) &&
              (other.negated == @negated)
          )
        end

        def &(other : Node)
          combine(other, SQL::PredicateConnector::AND)
        end

        def |(other : Node)
          combine(other, SQL::PredicateConnector::OR)
        end

        def - : self
          negated_parent = self.class.new
          negated_parent.add(self, SQL::PredicateConnector::AND)
          negated_parent.negate
          negated_parent
        end

        protected def add(other : Node, conn : SQL::PredicateConnector)
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
