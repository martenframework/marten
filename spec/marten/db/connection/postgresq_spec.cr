require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
  describe Marten::DB::Connection::PostgreSQL do
    describe "#quote" do
      it "produces expected quoted strings" do
        conn = Marten::DB::Connection.default
        conn.quote("column_name").should eq %{"column_name"}
      end
    end

    describe "#introspector" do
      it "returns the expected introspector instance" do
        conn = Marten::DB::Connection.default
        conn.introspector.should be_a Marten::DB::Management::Introspector::PostgreSQL
      end
    end

    describe "#left_operand_for" do
      it "returns the expected operand for an icontains predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for("table.column", "icontains").should eq "UPPER(table.column)"
      end

      it "returns the expected operand for an iendswith predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for("table.column", "iendswith").should eq "UPPER(table.column)"
      end

      it "returns the expected operand for an iexact predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for("table.column", "iexact").should eq "UPPER(table.column)"
      end

      it "returns the expected operand for an istartswith predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for("table.column", "istartswith").should eq "UPPER(table.column)"
      end

      it "returns the original id for other predicates" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for("table.column", "contains").should eq "table.column"
        conn.left_operand_for("table.column", "exact").should eq "table.column"
      end
    end

    describe "#operator_for" do
      it "returns the expected operator for a contains predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("contains").should eq "LIKE %s"
      end

      it "returns the expected operator for an endswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("endswith").should eq "LIKE %s"
      end

      it "returns the expected operator for an exact predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("exact").should eq "= %s"
      end

      it "returns the expected operator for an icontains predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("icontains").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for an iendswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("iendswith").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for an iexact predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("iexact").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for an istartswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("istartswith").should eq "LIKE UPPER(%s)"
      end

      it "returns the expected operator for a startswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("startswith").should eq "LIKE %s"
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

    describe "#schema_editor" do
      it "returns the expected schema editor instance" do
        conn = Marten::DB::Connection.default
        conn.schema_editor.should be_a Marten::DB::Management::SchemaEditor::PostgreSQL
      end
    end

    describe "#scheme" do
      it "returns the expected scheme" do
        conn = Marten::DB::Connection.default
        conn.scheme.should eq "postgres"
      end
    end
  end
{% end %}
