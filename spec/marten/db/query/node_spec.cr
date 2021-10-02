require "./spec_helper"

describe Marten::DB::Query::Node do
  describe "::new" do
    it "allows to initialize a query node from keyword arguments" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "foo"  => "bar",
          "test" => 42,
        }
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        abc: true,
        xyz: "test"
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "abc" => true,
          "xyz" => "test",
        }
      )
    end

    it "allows to initialize a query node from a hash" do
      node_1 = Marten::DB::Query::Node.new({"foo" => "bar", "test" => 42})
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "foo"  => "bar",
          "test" => 42,
        }
      )

      node_2 = Marten::DB::Query::Node.new(
        {"abc" => true, "xyz" => "test"},
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "abc" => true,
          "xyz" => "test",
        }
      )
    end

    it "allows to initialize a query node from a named tuple" do
      node_1 = Marten::DB::Query::Node.new({foo: "bar", test: 42})
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "foo"  => "bar",
          "test" => 42,
        }
      )

      node_2 = Marten::DB::Query::Node.new(
        {abc: true, xyz: "test"},
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "abc" => true,
          "xyz" => "test",
        }
      )
    end

    it "allows to initialize a query node from a filter hash" do
      node_1 = Marten::DB::Query::Node.new(
        children: [] of Marten::DB::Query::Node,
        connector: Marten::DB::Query::SQL::PredicateConnector::AND,
        negated: false,
        filters: Marten::DB::Query::Node::FilterHash{"foo" => "bar", "test" => 42}
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "foo"  => "bar",
          "test" => 42,
        }
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        filters: Marten::DB::Query::Node::FilterHash{"abc" => true, "xyz" => "test"},
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "abc" => true,
          "xyz" => "test",
        }
      )
    end

    it "converts unexpected filter values to their string representations" do
      node = Marten::DB::Query::Node.new(path: Path["foo/bar"])
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.filters.should eq(
        Marten::DB::Query::Node::FilterHash{
          "path" => "foo/bar",
        }
      )
    end
  end

  describe "#==" do
    it "returns true if two nodes are the same" do
      other_node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node_1 = Marten::DB::Query::Node.new(
        {"abc" => true, :xyz => "test"},
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        abc: true,
        xyz: "test"
      )

      node_1.should eq node_2
    end

    it "returns false if the filters are not the same" do
      other_node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node_1 = Marten::DB::Query::Node.new(
        {abc: true, xyz: "test"},
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        other: true,
        xyz: "test"
      )

      node_1.should_not eq node_2
    end

    it "returns false if the children are not the same" do
      other_node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node_1 = Marten::DB::Query::Node.new(
        {"abc" => true, :xyz => "test"},
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [] of Marten::DB::Query::Node,
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        abc: true,
        xyz: "test"
      )

      node_1.should_not eq node_2
    end

    it "returns false if the connectors are not the same" do
      other_node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node_1 = Marten::DB::Query::Node.new(
        {"abc" => true, :xyz => "test"},
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::AND,
        negated: true,
        abc: true,
        xyz: "test"
      )

      node_1.should_not eq node_2
    end

    it "returns false if the negated flags are not the same" do
      other_node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node_1 = Marten::DB::Query::Node.new(
        {"abc" => true, :xyz => "test"},
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: false,
        abc: true,
        xyz: "test"
      )

      node_1.should_not eq node_2
    end
  end

  describe "#&" do
    it "is able to combine a node with another one using a logical AND operation" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_2 = Marten::DB::Query::Node.new(xyz: "ok")

      node = node_1 & node_2

      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.children.should eq [node_1, node_2]
    end

    it "works as expected for more complex node combinations" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_2 = Marten::DB::Query::Node.new(xyz: "ok")
      node_3 = Marten::DB::Query::Node.new(john: "doe")

      combined_node = node_1 | node_2

      node = node_3 & combined_node

      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.children.should eq [node_3, combined_node]
    end
  end

  describe "#|" do
    it "is able to combine a node with another one using a logical OR operation" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_2 = Marten::DB::Query::Node.new(xyz: "ok")

      node = node_1 | node_2

      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node.children.should eq [node_1, node_2]
    end

    it "works as expected for more complex node combinations" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_2 = Marten::DB::Query::Node.new(xyz: "ok")
      node_3 = Marten::DB::Query::Node.new(john: "doe")

      combined_node = node_1 & node_2

      node = node_3 | combined_node

      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node.children.should eq [node_3, combined_node]
    end
  end

  describe "#-" do
    it "is able to negate a node" do
      node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      negated_node = -node

      negated_node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      negated_node.negated.should be_true
      negated_node.children.should eq [node]
    end
  end
end
