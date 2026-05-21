require "./spec_helper"

for_postgresql do
  describe Marten::DB::Connection::PostgreSQL do
    describe "#bulk_batch_size" do
      it "returns the specified records count" do
        conn = Marten::DB::Connection.default
        conn.bulk_batch_size(records_count: 1000, values_count: 10).should eq 1000
      end
    end

    describe "#distinct_clause_for" do
      it "returns the expected distinct clause if no column names are specified" do
        conn = Marten::DB::Connection.default
        conn.distinct_clause_for([] of String).should eq "DISTINCT"
      end

      it "returns the expected distinct clause if column names are specified" do
        conn = Marten::DB::Connection.default
        conn.distinct_clause_for(["foo"]).should eq "DISTINCT ON (foo)"
        conn.distinct_clause_for(["foo", "bar"]).should eq "DISTINCT ON (foo, bar)"
      end
    end

    describe "#quote" do
      it "produces expected quoted strings" do
        conn = Marten::DB::Connection.default
        conn.quote("column_name").should eq %{"column_name"}
      end
    end

    describe "#limit_value" do
      it "returns the passed value if it is not nil" do
        conn = Marten::DB::Connection.default
        conn.limit_value(123_456_789).should eq 123_456_789
      end

      it "returns nil if the passed value is nil" do
        conn = Marten::DB::Connection.default
        conn.limit_value(nil).should be_nil
      end
    end

    describe "#left_operand_for_predicate" do
      it "returns the expected operand for an icontains predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for_predicate("table.column", "icontains").should eq "UPPER(table.column)"
      end

      it "returns the expected operand for an iendswith predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for_predicate("table.column", "iendswith").should eq "UPPER(table.column)"
      end

      it "returns the expected operand for an iexact predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for_predicate("table.column", "iexact").should eq "UPPER(table.column)"
      end

      it "returns the expected operand for an istartswith predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for_predicate("table.column", "istartswith").should eq "UPPER(table.column)"
      end

      it "returns the original id for other predicates" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for_predicate("table.column", "contains").should eq "table.column"
        conn.left_operand_for_predicate("table.column", "exact").should eq "table.column"
      end
    end

    describe "#max_name_size" do
      it "returns the expected value" do
        conn = Marten::DB::Connection.default
        conn.max_name_size.should eq 63
      end
    end

    describe "#operator_for_predicate" do
      it "returns the expected operator for a contains predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("contains").should eq "LIKE %s"
      end

      it "returns the expected operator for an endswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("endswith").should eq "LIKE %s"
      end

      it "returns the expected operator for an exact predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("exact").should eq "= %s"
      end

      it "returns the expected operator for a gt predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("gt").should eq "> %s"
      end

      it "returns the expected operator for a gte predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("gte").should eq ">= %s"
      end

      it "returns the expected operator for an icontains predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("icontains").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for an iendswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("iendswith").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for an iexact predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("iexact").should eq "= UPPER(%s)"
      end

      it "returns the expected operator for an istartswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("istartswith").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for a lt predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("lt").should eq "< %s"
      end

      it "returns the expected operator for a lte predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("lte").should eq "<= %s"
      end

      it "returns the expected operator for a startswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for_predicate("startswith").should eq "LIKE %s"
      end
    end

    describe "#left_operand_for_transformation" do
      it "returns transformation SQL for each supported transformation name" do
        conn = Marten::DB::Connection.default
        ref = "posts.created_at"
        conn.left_operand_for_transformation(ref, "year")
          .should eq "CAST(EXTRACT(YEAR FROM posts.created_at) AS INTEGER)"
        conn.left_operand_for_transformation(ref, "month")
          .should eq "CAST(EXTRACT(MONTH FROM posts.created_at) AS INTEGER)"
        conn.left_operand_for_transformation(ref, "day")
          .should eq "CAST(EXTRACT(DAY FROM posts.created_at) AS INTEGER)"
        conn.left_operand_for_transformation(ref, "hour")
          .should eq "CAST(EXTRACT(HOUR FROM posts.created_at) AS INTEGER)"
        conn.left_operand_for_transformation(ref, "minute")
          .should eq "CAST(EXTRACT(MINUTE FROM posts.created_at) AS INTEGER)"
        conn.left_operand_for_transformation(ref, "second")
          .should eq "CAST(EXTRACT(SECOND FROM posts.created_at) AS INTEGER)"
      end
    end

    describe "#parameter_id_for_ordered_argument" do
      it "returns the expected ordered argument identifier" do
        conn = Marten::DB::Connection.default
        conn.parameter_id_for_ordered_argument(1).should eq "$1"
        conn.parameter_id_for_ordered_argument(2).should eq "$2"
        conn.parameter_id_for_ordered_argument(3).should eq "$3"
        conn.parameter_id_for_ordered_argument(10).should eq "$10"
      end
    end

    describe "#quote_char" do
      it "returns the expected quote character" do
        conn = Marten::DB::Connection.default
        conn.quote_char.should eq '"'
      end
    end

    describe "#scheme" do
      it "returns the expected scheme" do
        conn = Marten::DB::Connection.default
        conn.scheme.should eq "postgres"
      end
    end

    describe "#supports_logical_xor?" do
      it "returns false" do
        conn = Marten::DB::Connection.default
        conn.supports_logical_xor?.should be_false
      end
    end
  end
end
