require "./spec_helper"

describe Marten::DB::Management::Statement do
  describe "#params" do
    it "returns the statement parameters" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo", "bar"]
        )
      )

      statement.params.size.should eq 1
      statement.params["column"].should be_a Marten::DB::Management::Statement::Columns
      column_statement = statement.params["column"].as(Marten::DB::Management::Statement::Columns)
      column_statement.table.should eq "test_table"
      column_statement.columns.should eq ["foo", "bar"]
    end
  end

  describe "#references_column?" do
    it "returns true if at least one statement references the passed column" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.references_column?("test_table", "foo").should be_true
    end

    it "returns false if no statements reference the passed column" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.references_column?("new_table", "new_column").should be_false
    end

    it "returns false for string parameters" do
      statement = Marten::DB::Management::Statement.new("template", raw_name: "raw_name")
      statement.references_column?("new_table", "new_column").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if at least one statement references the passed table" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.references_table?("test_table").should be_true
      statement.references_table?("other_table").should be_true
    end

    it "returns trufalsee if no statements reference the passed table" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.references_table?("new_table").should be_false
    end

    it "returns false for string parameters" do
      statement = Marten::DB::Management::Statement.new("template", raw_name: "raw_name")
      statement.references_table?("new_table").should be_false
    end
  end

  describe "#rename_column" do
    it "properly renames columns in statements that reference the passed column" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.rename_column("test_table", "foo", "renamed_foo")

      statement.params["column_1"].as(Marten::DB::Management::Statement::Columns).columns.should eq ["renamed_foo"]
      statement.params["column_2"].as(Marten::DB::Management::Statement::Columns).columns.should eq ["bar"]
      statement.params["column_3"].as(Marten::DB::Management::Statement::Columns).columns.should eq ["other_column"]
    end

    it "does not rename columns in statements that don't reference the passed column" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.rename_column("new_table", "new_column", "renamed_new_column")

      statement.params["column_1"].as(Marten::DB::Management::Statement::Columns).columns.should eq ["foo"]
      statement.params["column_2"].as(Marten::DB::Management::Statement::Columns).columns.should eq ["bar"]
      statement.params["column_3"].as(Marten::DB::Management::Statement::Columns).columns.should eq ["other_column"]
    end

    it "does nothing to string parameters" do
      statement = Marten::DB::Management::Statement.new("template", raw_name: "raw_name")
      statement.rename_column("new_table", "new_column", "renamed_new_column")
      statement.params["raw_name"].should eq "raw_name"
    end
  end

  describe "#rename_table" do
    it "properly renames tables in statements that reference the passed table" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.rename_table("test_table", "renamed_test_table")

      statement.params["column_1"].as(Marten::DB::Management::Statement::Columns).table.should eq "renamed_test_table"
      statement.params["column_2"].as(Marten::DB::Management::Statement::Columns).table.should eq "renamed_test_table"
      statement.params["column_3"].as(Marten::DB::Management::Statement::Columns).table.should eq "other_table"
    end

    it "does not rename tables in statements that don't reference the passed table" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column_1: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo"]
        ),
        column_2: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["bar"]
        ),
        column_3: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "other_table",
          ["other_column"]
        )
      )

      statement.rename_table("new_table", "renamed_new_table")

      statement.params["column_1"].as(Marten::DB::Management::Statement::Columns).table.should eq "test_table"
      statement.params["column_2"].as(Marten::DB::Management::Statement::Columns).table.should eq "test_table"
      statement.params["column_3"].as(Marten::DB::Management::Statement::Columns).table.should eq "other_table"
    end

    it "does nothing to string parameters" do
      statement = Marten::DB::Management::Statement.new("template", raw_name: "raw_name")
      statement.rename_table("new_table", "renamed_new_table")
      statement.params["raw_name"].should eq "raw_name"
    end
  end

  describe "#template" do
    it "returns the statement template" do
      statement = Marten::DB::Management::Statement.new(
        "template",
        column: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["foo", "bar"]
        )
      )

      statement.template.should eq "template"
    end
  end

  describe "#to_s" do
    it "properly renders the template by making use of the params" do
      statement = Marten::DB::Management::Statement.new(
        (
          <<-SQL
            ALTER TABLE %{table}
            ADD CONSTRAINT %{constraint}
            FOREIGN KEY (%{column})
            REFERENCES %{to_table} (%{to_column})
          SQL
        ),
        table: Marten::DB::Management::Statement::Table.new(->(x : String) { x }, "test_table"),
        constraint: Marten::DB::Management::Statement::ForeignKeyName.new(
          ->(_x : String, _y : Array(String), _z : String) { "indexname" },
          "test_table",
          "test_column",
          "test_to_table",
          "test_to_column"
        ),
        column: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_table",
          ["test_column"]
        ),
        to_table: Marten::DB::Management::Statement::Table.new(->(x : String) { x }, "test_to_table"),
        to_column: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "test_to_table",
          ["test_to_column"]
        )
      )

      statement.to_s.strip.should eq (
        <<-SQL
          ALTER TABLE test_table
          ADD CONSTRAINT indexname
          FOREIGN KEY (test_column)
          REFERENCES test_to_table (test_to_column)
        SQL
      ).strip
    end
  end
end
