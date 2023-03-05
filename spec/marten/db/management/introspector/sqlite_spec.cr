require "./spec_helper"

for_sqlite do
  describe Marten::DB::Management::Introspector::SQLite do
    describe "#columns_info" do
      before_each do
        introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

        if introspector.table_names.includes?("schema_introspector_test_table")
          schema_editor.delete_table("schema_introspector_test_table")
        end
      end

      it "returns the details of the columns of a specific table" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_introspector_test_table",
          columns: [
            Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            Marten::DB::Management::Column::BigInt.new("foo", null: true),
            Marten::DB::Management::Column::String.new("bar", max_size: 155, null: false, default: "hello"),
          ] of Marten::DB::Management::Column::Base
        )

        schema_editor.create_table(table_state)

        introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

        columns_details = introspector.columns_details(table_state.name)
        columns_details.sort_by!(&.name)

        columns_details.size.should eq 3

        columns_details[0].name.should eq "bar"
        columns_details[0].type.should eq "varchar(155)"
        columns_details[0].nullable?.should be_false
        columns_details[0].default.should eq "'hello'"
        columns_details[0].character_maximum_length.should be_nil

        columns_details[1].name.should eq "foo"
        columns_details[1].type.downcase.should eq "integer"
        columns_details[1].nullable?.should be_true
        columns_details[1].default.should be_nil
        columns_details[1].character_maximum_length.should be_nil

        columns_details[2].name.should eq "id"
        columns_details[2].type.downcase.should eq "integer"
        columns_details[2].nullable?.should be_false
        columns_details[2].default.should be_nil
        columns_details[2].character_maximum_length.should be_nil
      end
    end

    describe "foreign_key_constraint_names" do
      it "returns an empty array" do
        introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
        introspector.foreign_key_constraint_names("test_table", "test_column").should be_empty
      end
    end

    describe "#index_names" do
      it "returns the index names for a specific table and column" do
        connection = Marten::DB::Connection.default
        introspector = Marten::DB::Management::Introspector.for(connection)

        index_names_1 = introspector.index_names(TestUser.db_table, "email")
        index_names_1.should eq ["index_app_test_user_on_email"]
      end
    end

    describe "#primary_key_constraint_names" do
      it "returns an empty array" do
        connection = Marten::DB::Connection.default
        introspector = Marten::DB::Management::Introspector.for(connection)

        introspector.primary_key_constraint_names(Post.db_table, "id").should be_empty
        introspector.primary_key_constraint_names(Post.db_table, "author_id").should be_empty
      end
    end

    describe "#table_names" do
      it "returns the table names of the associated database connection" do
        connection = Marten::DB::Connection.default
        introspector = Marten::DB::Management::Introspector.for(connection)

        introspector.table_names.should contain(TestUser.db_table)
        introspector.table_names.should_not contain("unknown_table")
      end
    end

    describe "#unique_constraint_names" do
      it "returns the unique constraint names of a specific table" do
        connection = Marten::DB::Connection.default
        introspector = Marten::DB::Management::Introspector.for(connection)

        constraint_names = [] of String

        Marten::DB::Connection.default.open do |db|
          db.query(
            <<-SQL
              SELECT
                il.name AS constraint_name,
                ii.name AS column_name
              FROM
                sqlite_master AS m,
                pragma_index_list(m.name) AS il,
                pragma_index_info(il.name) AS ii
              WHERE
                m.type = 'table' AND
                il.origin = 'u' AND
                m.tbl_name = '#{Tag.db_table}'
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              column_name = rs.read(String)
              constraint_names << constraint_name if column_name == "name"
            end
          end
        end

        introspector.unique_constraint_names(Tag.db_table, "name").should eq constraint_names
      end
    end
  end
end
