require "./spec_helper"

describe Marten::DB::Management::Column::Reference do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )
      )

      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).should eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          null: true
        )
      )

      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).should eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          unique: true
        )
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should_not eq(
        Marten::DB::Management::Column::Reference.new(
          "other",
          to_table: "other_table",
          to_column: "other_column"
        )
      )
    end

    it "returns false if two column objects don't have the same target table" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should_not eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "new_table",
          to_column: "other_column"
        )
      )
    end

    it "returns false if two column objects don't have the same target column" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      ).should_not eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "new_column"
        )
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).should_not eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          null: false
        )
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).should_not eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          unique: false
        )
      )
    end

    it "returns true if two column objects have the same foreign key property" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: false,
      ).should eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          foreign_key: false
        )
      )
    end

    it "returns false if two column objects don't have the same foreign key property" do
      Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: true,
      ).should_not eq(
        Marten::DB::Management::Column::Reference.new(
          "test",
          to_table: "other_table",
          to_column: "other_column",
          foreign_key: false
        )
      )
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.to_column.should eq "other_column"
      cloned_column_1.to_table.should eq "other_table"
      cloned_column_1.should eq Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )

      column_2 = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      )
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      )

      column_3 = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      )
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      )
    end

    it "clones the underlying target column" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id"
      )
      column.contribute_to_project(project_state)

      cloned_column = column.clone

      for_mysql { cloned_column.sql_type(Marten::DB::Connection.default).should eq "bigint" }
      for_postgresql { cloned_column.sql_type(Marten::DB::Connection.default).should eq "bigint" }
      for_sqlite { cloned_column.sql_type(Marten::DB::Connection.default).should eq "integer" }
    end

    it "clones the underlying foreign key configuration" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id",
        foreign_key: false
      )
      column.contribute_to_project(project_state)

      cloned_column = column.clone

      cloned_column.foreign_key?.should be_false
    end
  end

  describe "#foreign_key?" do
    it "returns true by default" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.foreign_key?.should be_true
    end

    it "returns true if explicitly set that way" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: true
      )
      column.foreign_key?.should be_true
    end

    it "returns false if explicitly set that way" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: false
      )
      column.foreign_key?.should be_false
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have different names but have the same properties" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column"
        )
      ).should be_true

      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          null: true
        )
      ).should be_true

      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          unique: true
        )
      ).should be_true
    end

    it "returns false if two column objects don't have the same target table" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "new_table",
          to_column: "other_column"
        )
      ).should be_false
    end

    it "returns false if two column objects don't have the same target column" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "other_table",
          to_column: "new_column"
        )
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          null: false
        )
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "bar",
          to_table: "other_table",
          to_column: "other_column",
          unique: false
        )
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column"
      ).same_config?(
        Marten::DB::Management::Column::Int.new("foo")
      ).should be_false
    end

    it "returns true if two column objects have the same foreign key configuration" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: false
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "foo",
          to_table: "other_table",
          to_column: "other_column",
          foreign_key: false
        )
      ).should be_true
    end

    it "returns false if two column objects don't have the same foreign key configuration" do
      Marten::DB::Management::Column::Reference.new(
        "foo",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: true
      ).same_config?(
        Marten::DB::Management::Column::Reference.new(
          "foo",
          to_table: "other_table",
          to_column: "other_column",
          foreign_key: false
        )
      ).should be_false
    end
  end

  describe "#serialize_args" do
    it "returns the expected serialized version of a simple column" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.serialize_args.should eq %{:test, :reference, to_table: :other_table, to_column: :other_column}
    end

    it "returns the expected serialized version of a simple column that is a nullable" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        null: true
      )
      column.serialize_args.should eq(
        %{:test, :reference, to_table: :other_table, to_column: :other_column, null: true}
      )
    end

    it "returns the expected serialized version of a simple column that is unique" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        unique: true
      )
      column.serialize_args.should eq(
        %{:test, :reference, to_table: :other_table, to_column: :other_column, unique: true}
      )
    end

    it "returns the expected serialized version of a simple column that is not indexed" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        index: false
      )
      column.serialize_args.should eq(
        %{:test, :reference, to_table: :other_table, to_column: :other_column, index: false}
      )
    end

    it "returns the expected serialized version of a simple column that is not a foreign key" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column",
        foreign_key: false
      )
      column.serialize_args.should eq(
        %{:test, :reference, to_table: :other_table, to_column: :other_column, foreign_key: false}
      )
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id"
      )
      column.contribute_to_project(project_state)

      for_mysql { column.sql_type(Marten::DB::Connection.default).should eq "bigint" }
      for_postgresql { column.sql_type(Marten::DB::Connection.default).should eq "bigint" }
      for_sqlite { column.sql_type(Marten::DB::Connection.default).should eq "integer" }
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id"
      )
      column.contribute_to_project(project_state)

      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end

  describe "#to_column" do
    it "returns the targetted column name" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.to_column.should eq "other_column"
    end
  end

  describe "#to_table" do
    it "returns the targetted table name" do
      column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: "other_table",
        to_column: "other_column"
      )
      column.to_table.should eq "other_table"
    end
  end
end
