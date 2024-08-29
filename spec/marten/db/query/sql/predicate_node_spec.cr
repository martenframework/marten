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

    it "allows to initialize a predicate node with a raw predicate without params" do
      node = Marten::DB::Query::SQL::PredicateNode.new(
        "title = 'Example title'",
      )
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false

      node.raw_predicate.should eq({predicate: "title = 'Example title'", params: [] of ::DB::Any})
    end

    it "allows to initialize a predicate node with a raw predicate with an array of params" do
      node = Marten::DB::Query::SQL::PredicateNode.new(
        raw_predicate: "title = ?",
        params: ["foo"] of ::DB::Any
      )
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false

      node.raw_predicate.should eq({predicate: "title = ?", params: ["foo"] of ::DB::Any})
    end

    it "allows to initialize a predicate node with a raw predicate with a hash of params" do
      node = Marten::DB::Query::SQL::PredicateNode.new(
        raw_predicate: "title = :title",
        params: {"title" => "foo"} of String => ::DB::Any
      )
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false

      node.raw_predicate.should eq({predicate: "title = :title", params: {"title" => "foo"} of String => ::DB::Any})
    end
  end

  describe "#==" do
    it "returns true if two nodes with filter predicates are the same" do
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

    it "returns true if two nodes with raw predicates are the same" do
      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        raw_predicate: "title = ?",
        params: ["foo"] of ::DB::Any,
        negated: false,
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        raw_predicate: "title = ?",
        params: ["foo"] of ::DB::Any,
        negated: false,
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

    it "returns false if the raw predicates are not the same" do
      node_1 = Marten::DB::Query::SQL::PredicateNode.new(
        raw_predicate: "title = ?",
        params: ["foo"] of ::DB::Any,
        negated: false,
      )

      node_2 = Marten::DB::Query::SQL::PredicateNode.new(
        raw_predicate: "subtitle = ?",
        params: ["foo"] of ::DB::Any,
        negated: false,
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

    it "adds a new child node to the parent's children containing the passed node if the connector is XOR" do
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

      node_2.add(node_3, Marten::DB::Query::SQL::PredicateConnector::XOR)

      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::XOR
      node_2.children.first.negated.should be_true
      node_2.children.first.connector.should eq Marten::DB::Query::SQL::PredicateConnector::OR
      node_2.children.first.predicates.should eq [predicate_1]
      node_2.children.first.children.should eq [node_1]
      node_2.children.last.should eq node_3
    end

    it "adds the passed node as expected if the connector is XOR and an equivalent node is already in the children" do
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
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::AND,
        false,
        predicate_1,
        predicate_2
      )

      node_2.add(node_3, Marten::DB::Query::SQL::PredicateConnector::XOR)

      node_2.connector.should eq Marten::DB::Query::SQL::PredicateConnector::XOR
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

  describe "#replace_table_alias_prefix" do
    it "properly replaces the table alias prefix in the predicate node, its children, and predicates" do
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

      node_1.replace_table_alias_prefix({"t1" => "p1", "t2" => "p2"})

      node_1.filter_predicates[0].alias_prefix.should eq "p1"
      node_1.filter_predicates[1].alias_prefix.should eq "p2"

      node_2.children[0].filter_predicates[0].alias_prefix.should eq "p1"
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

    it "properly generates the expected SQL for a simple predicate with an OR connector" do
      predicate_1 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Foo", "t1")
      predicate_2 = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "Bar", "t2")

      node = Marten::DB::Query::SQL::PredicateNode.new(
        Array(Marten::DB::Query::SQL::PredicateNode).new,
        Marten::DB::Query::SQL::PredicateConnector::XOR,
        false,
        predicate_1,
        predicate_2
      )

      for_mysql do
        node.to_sql(Marten::DB::Connection.default).should eq(
          {"(t1.title = %s XOR t2.title = %s)", ["Foo", "Bar"]}
        )
      end

      for_postgresql do
        node.to_sql(Marten::DB::Connection.default).should eq(
          {
            "((CASE WHEN t1.title = %s THEN 1 ELSE 0 END + CASE WHEN t2.title = %s THEN 1 ELSE 0 END) = 1)",
            ["Foo", "Bar"],
          }
        )
      end

      for_sqlite do
        node.to_sql(Marten::DB::Connection.default).should eq(
          {
            "((CASE WHEN t1.title = %s THEN 1 ELSE 0 END + CASE WHEN t2.title = %s THEN 1 ELSE 0 END) = 1)",
            ["Foo", "Bar"],
          }
        )
      end
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

    it "properly generates the expected SQL from the raw predicate" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node = Marten::DB::Query::SQL::PredicateNode.new(
        "title = ?",
        raw_params
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"title = %s", ["Example title"]}
      )
    end

    it "properly generates the expected SQL from the raw predicate if it contains the '%'' character" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node = Marten::DB::Query::SQL::PredicateNode.new(
        "title LIKE '?%'",
        raw_params
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"title LIKE '%s%%'", ["Example title"]}
      )
    end
  end
end
