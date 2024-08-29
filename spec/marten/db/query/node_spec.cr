require "./spec_helper"

describe Marten::DB::Query::Node do
  describe "::new" do
    it "allows to initialize a query node from keyword arguments" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.filters.should eq(
        Marten::DB::Query::Node::Filters{
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
        Marten::DB::Query::Node::Filters{
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
        Marten::DB::Query::Node::Filters{
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
        Marten::DB::Query::Node::Filters{
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
        Marten::DB::Query::Node::Filters{
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
        Marten::DB::Query::Node::Filters{
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
        filters: Marten::DB::Query::Node::Filters{"foo" => "bar", "test" => 42}
      )
      node_1.children.should be_empty
      node_1.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node_1.negated.should be_false
      node_1.filters.should eq(
        Marten::DB::Query::Node::Filters{
          "foo"  => "bar",
          "test" => 42,
        }
      )

      node_2 = Marten::DB::Query::Node.new(
        children: [node_1],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true,
        filters: Marten::DB::Query::Node::Filters{"abc" => true, "xyz" => "test"},
      )
      node_2.children.should eq [node_1]
      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.negated.should be_true
      node_2.filters.should eq(
        Marten::DB::Query::Node::Filters{
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
        Marten::DB::Query::Node::Filters{
          "path" => "foo/bar",
        }
      )
    end

    it "initializes a node from a filter consisting of an array of model records" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      node = Marten::DB::Query::Node.new(tag: [tag_1, tag_2, tag_3])
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.filters.should eq(
        Marten::DB::Query::Node::Filters{
          "tag" => [tag_1, tag_2, tag_3] of Marten::DB::Model,
        }
      )
    end

    it "initializes a node from a filter consisting of a query set" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      node = Marten::DB::Query::Node.new(tag: Tag.all.order(:name))
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.filters.should eq(
        Marten::DB::Query::Node::Filters{
          "tag" => [tag_3, tag_2, tag_1] of Marten::DB::Model,
        }
      )
    end

    it "initializes a node from a filter consisting of an array of unsupported and supported filter values" do
      node = Marten::DB::Query::Node.new(test: [Path["foo/bar"], 42, "foo"])
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.filters.should eq(
        Marten::DB::Query::Node::Filters{
          "test" => ["foo/bar", 42, "foo"] of Marten::DB::Field::Any,
        }
      )
    end

    it "allows to initialize a query node from a raw predicate without params" do
      node = Marten::DB::Query::Node.new("field IS NOT NULL")

      node.raw_predicate?.should be_true
      node.raw_predicate[:predicate].should eq "field IS NOT NULL"
      node.raw_predicate[:params].should be_empty
    end

    it "allows to initialize a query node from a raw predicate with an array of params" do
      node = Marten::DB::Query::Node.new(raw_predicate: "field = ?", params: ["foo"] of ::DB::Any)

      node.raw_predicate?.should be_true
      node.raw_predicate[:predicate].should eq "field = ?"
      node.raw_predicate[:params].should eq ["foo"]
    end

    it "allows to initialize a query node from a raw predicate with a hash of params" do
      node = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any
      )

      node.raw_predicate?.should be_true
      node.raw_predicate[:predicate].should eq "field = :param"
      node.raw_predicate[:params].should eq({"param" => "foo"})
    end
  end

  describe "#==" do
    it "returns true if two nodes with filters are the same" do
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

    it "returns true if two nodes with raw predicates are the same" do
      other_node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node_1 = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any,
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
      )

      node_2 = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any,
        children: [other_node],
        connector: Marten::DB::Query::SQL::PredicateConnector::OR,
        negated: true
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

  describe "#^" do
    it "is able to combine a node with another one using a logical OR operation" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_2 = Marten::DB::Query::Node.new(xyz: "ok")

      node = node_1 ^ node_2

      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::XOR
      node.children.should eq [node_1, node_2]
    end

    it "always combine identical nodes" do
      node_1 = Marten::DB::Query::Node.new(foo: "bar", test: 42)
      node_2 = Marten::DB::Query::Node.new(xyz: "bar", test: 42)

      node = node_1 ^ node_2

      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::XOR
      node.children.should eq [node_1, node_2]
    end
  end

  describe "#filters" do
    it "returns the filters of the node" do
      node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node.filters.should eq(
        Marten::DB::Query::Node::Filters{
          "foo"  => "bar",
          "test" => 42,
        }
      )
    end

    it "raises if the node is associated with a raw predicate" do
      node = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any
      )

      expect_raises(TypeCastError) do
        node.filters
      end
    end
  end

  describe "#filters?" do
    it "returns true if the node has filters" do
      node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node.filters?.should be_true
    end

    it "returns false if the node has a raw predicate" do
      node = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any
      )

      node.filters?.should be_false
    end
  end

  describe "#raw_predicate" do
    it "returns the raw predicate of the node" do
      node = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any
      )

      node.raw_predicate.should eq(
        {
          predicate: "field = :param",
          params:    {"param" => "foo"},
        }
      )
    end

    it "raises if the node is associated with filters" do
      node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      expect_raises(TypeCastError) do
        node.raw_predicate
      end
    end
  end

  describe "#raw_predicate?" do
    it "returns true if the node has a raw predicate" do
      node = Marten::DB::Query::Node.new(
        raw_predicate: "field = :param",
        params: {"param" => "foo"} of String => ::DB::Any
      )

      node.raw_predicate?.should be_true
    end

    it "returns false if the node has filters" do
      node = Marten::DB::Query::Node.new(foo: "bar", test: 42)

      node.raw_predicate?.should be_false
    end
  end
end
