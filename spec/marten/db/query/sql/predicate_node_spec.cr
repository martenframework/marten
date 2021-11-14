require "./spec_helper"

describe Marten::DB::Query::SQL::PredicateNode do
  describe "::new" do
    it "allows to initialize a predicate node from positional arguments" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.predicates.should eq [predicate_1, predicate_2]

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.predicates.should eq [predicate_1]
    end

    it "allows to initialize a predicate node from an array of predicates" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        children: Array(Marten::DB::Query::SQL::PredicateNode).new,
        connector: Marten::DB::Query::SQL::PredicateConnector::AND,
        negated: false,
        predicates: [predicate_1, predicate_2] of Marten::DB::Query::SQL::Predicate::Base
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.predicates.should eq [predicate_1, predicate_2]

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        predicates: [predicate_1] of Marten::DB::Query::SQL::Predicate::Base
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.predicates.should eq [predicate_1]
    end
  end

  describe "#==" do
    it "returns true if two nodes are the same" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_1.should eq node_2
    end

    it "returns false if the predicates are not the same" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1
      )

      node_1.should_not eq node_2
    end

    it "returns false if the children are not the same" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_1.should_not eq node_2
    end

    it "returns false if the connectors are not the same" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::OR,
        false,
        predicate_1,
        predicate_2
      )

      node_1.should_not eq node_2
    end

    it "returns false if the negated flags are not the same" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        true,
        predicate_1,
        predicate_2
      )

      node_1.should_not eq node_2
    end
  end

  describe "#add" do
    it "does nothing if the passed node is already in the parent's children" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.predicates.should eq [predicate_1, predicate_2]

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.predicates.should eq [predicate_1]

      node_2.add(node_1, Marten::DB::Query::SQL::PredicateConnector::AND)

      node_2.children.should eq [node_1]
    end

    it "adds the passed node to the parent's children if the connector is the same" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.predicates.should eq [predicate_1, predicate_2]

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.predicates.should eq [predicate_1]

      node_3 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )

      node_2.add(node_3, Marten::DB::Query::SQL::PredicateConnector::OR)

      node_2.children.should eq [node_1, node_3]
    end

    it "adds a new child node to the parent's children containing the passed node if the connector is different" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.predicates.should eq [predicate_1, predicate_2]

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.predicates.should eq [predicate_1]

      node_3 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )

      node_2.add(node_3, Marten::DB::Query::SQL::PredicateConnector::AND)

      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_2.children.first.negated.should be_true
      node_2.children.first.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.children.first.predicates.should eq [predicate_1]
      node_2.children.first.children.should eq [node_1]
      node_2.children.last.should eq node_3
    end
  end

  describe "#clone" do
    it "properly clones a predicate node" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.predicates.should eq [predicate_1, predicate_2]

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        [node_1],
        Marten::DB::Query::SQL::PredicateConnector::OR,
        true,
        predicate_1
      )

      cloned = node_2.clone

      cloned.object_id.should_not eq node_2.object_id

      cloned.children.size.should eq 1
      cloned.children[0].children.should be_empty
      cloned.children[0].connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      cloned.children[0].negated.should be_false
      cloned.children[0].predicates.should eq [predicate_1, predicate_2]

      cloned.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      cloned.negated.should be_true
      cloned.predicates.should eq [predicate_1]
    end
  end

  describe "#to_sql" do
    it "properly generates the expected SQL for a simple predicate with an AND connector" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"(t1.title = %s AND t2.title = %s)", ["Foo", "Bar"]}
      )
    end

    it "properly generates the expected SQL for a simple predicate with an OR connector" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::OR,
        false,
        predicate_1,
        predicate_2
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"(t1.title = %s OR t2.title = %s)", ["Foo", "Bar"]}
      )
    end

    it "properly generates the expected SQL for a simple negated predicate" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        true,
        predicate_1,
        predicate_2
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"(NOT (t1.title = %s AND t2.title = %s))", ["Foo", "Bar"]}
      )
    end

    it "properly handles complex nodes" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        children: Array(Marten::DB::Query::SQL::PredicateNode).new,
        connector: Marten::DB::Query::SQL::PredicateConnector::AND,
        negated: false,
        predicates: [predicate_1, predicate_2] of Marten::DB::Query::SQL::Predicate::Base
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        predicates: [predicate_1] of Marten::DB::Query::SQL::Predicate::Base
      )

      node_2.to_sql(Marten::DB::Connection.default).should eq(
        {"(NOT (t1.title = %s OR (t1.title = %s AND t2.title = %s)))", ["Foo", "Foo", "Bar"]}
      )
    end
  end
end
