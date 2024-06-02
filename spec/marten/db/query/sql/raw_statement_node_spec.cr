require "./spec_helper"

describe Marten::DB::Query::SQL::RawStatementNode do
  describe "::new" do
    it "allows to initialize a raw statement node with no arguments" do
      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = 'Example title'",
      )
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.statement.should eq("title = 'Example title'")
      node.params.should eq([] of ::DB::Any)
    end

    it "allows to initialize a raw statement node from positional arguments" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params
      )
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.statement.should eq("title = ?")
      node.params.should eq(["Example title"])
    end

    it "allows to initialize a raw statement node from named arguments" do
      raw_params = {} of String => ::DB::Any
      raw_params["title"] = "Example title"

      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = :title",
        raw_params
      )
      node.children.should be_empty
      node.connector.should eq Marten::DB::Query::SQL::PredicateConnector::AND
      node.negated.should be_false
      node.statement.should eq("title = :title")
      node.params.should eq({"title" => "Example title"})
    end
  end

  describe "#==" do
    it "returns true if two nodes are the same" do
      node_1 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = 'Example title'",
      )

      node_2 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = 'Example title'",
      )

      node_1.should eq node_2
    end

    it "returns false if the params are not the same" do
      raw_params_1 = [] of ::DB::Any
      raw_params_1 += ["Example title"]

      raw_params_2 = [] of ::DB::Any
      raw_params_2 += ["Second Example title"]

      node_1 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params_1
      )

      node_2 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params_2
      )

      node_1.should_not eq node_2
    end

    it "returns false if the connectors are not the same" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node_1 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params,
        connector: Marten::DB::Query::SQL::PredicateConnector::AND
      )

      node_2 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params,
        connector: Marten::DB::Query::SQL::PredicateConnector::OR
      )

      node_1.should_not eq node_2
    end

    it "returns false if the negated flags are not the same" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node_1 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params,
        negated: false
      )

      node_2 = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params,
        negated: true
      )

      node_1.should_not eq node_2
    end
  end

  describe "#clone" do
    it "properly clones a predicate node" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params
      )

      node.statement.should eq("title = ?")
      node.params.should eq(["Example title"])

      cloned = node.clone

      cloned.object_id.should_not eq node.object_id

      cloned.statement.should eq("title = ?")
      cloned.params.should eq(["Example title"])
    end
  end

  describe "#to_sql" do
    it "properly generates the expected SQL from the statement" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = ?",
        raw_params
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"title = %s", ["Example title"]}
      )
    end

    it "properly generates the expected SQL from a statement with % inside" do
      raw_params = [] of ::DB::Any
      raw_params += ["Example title"]

      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title LIKE '?%'",
        raw_params
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"title LIKE '%s%%'", ["Example title"]}
      )
    end

    it "properly generates the expected SQL for a simple negated predicate" do
      raw_params = {} of String => ::DB::Any
      raw_params["title"] = "Example title"

      node = Marten::DB::Query::SQL::RawStatementNode.new(
        "title = :title",
        raw_params
      )

      node.to_sql(Marten::DB::Connection.default).should eq(
        {"title = %s", ["Example title"]}
      )
    end
  end
end
