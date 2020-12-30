require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "sqlite" || !env("MARTEN_SPEC_DB_CONNECTION") %}
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
        conn.introspector.should be_a Marten::DB::Management::Introspector::SQLite
      end
    end

    describe "#left_operand_for" do
      it "returns the original id no matter the predicate" do
        conn = Marten::DB::Connection.default
        conn.left_operand_for("table.column", "contains").should eq "table.column"
        conn.left_operand_for("table.column", "istartswith").should eq "table.column"
      end
    end

    describe "#limit_value" do
      it "returns the passed value if it is not nil" do
        conn = Marten::DB::Connection.default
        conn.limit_value(123456789).should eq 123456789
      end

      it "returns -1 if the passed value is nil" do
        conn = Marten::DB::Connection.default
        conn.limit_value(nil).should eq -1
      end
    end

    describe "#operator_for" do
      it "returns the expected operator for a contains predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("contains").should eq "LIKE %s ESCAPE '\\'"
      end

      it "returns the expected operator for an endswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("endswith").should eq "LIKE %s ESCAPE '\\'"
      end

      it "returns the expected operator for an exact predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("exact").should eq "= %s"
      end

      it "returns the expected operator for an icontains predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("icontains").should eq "LIKE %s ESCAPE '\\'"
      end

      it "returns the expected operator for an iendswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("iendswith").should eq "LIKE %s ESCAPE '\\'"
      end

      it "returns the expected operator for an iexact predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("iexact").should eq "LIKE %s ESCAPE '\\'"
      end

      it "returns the expected operator for an istartswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("istartswith").should eq "LIKE %s ESCAPE '\\'"
      end

      it "returns the expected operator for a startswith predicate" do
        conn = Marten::DB::Connection.default
        conn.operator_for("startswith").should eq "LIKE %s ESCAPE '\\'"
      end
    end

    describe "#parameter_id_for_ordered_argument" do
      it "returns the expected ordered argument identifier" do
        conn = Marten::DB::Connection.default
        conn.parameter_id_for_ordered_argument(1).should eq "?"
        conn.parameter_id_for_ordered_argument(2).should eq "?"
        conn.parameter_id_for_ordered_argument(3).should eq "?"
        conn.parameter_id_for_ordered_argument(10).should eq "?"
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
        conn.schema_editor.should be_a Marten::DB::Management::SchemaEditor::SQLite
      end
    end

    describe "#scheme" do
      it "returns the expected scheme" do
        conn = Marten::DB::Connection.default
        conn.scheme.should eq "sqlite3"
      end
    end
  end
{% end %}
