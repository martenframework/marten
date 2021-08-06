require "./spec_helper"

for_sqlite do
  describe Marten::DB::Management::Introspector::SQLite do
    describe "foreign_key_constraint_names" do
      it "returns an empty array" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.foreign_key_constraint_names("test_table", "test_column").should be_empty
      end
    end

    describe "#index_names" do
      it "returns the index names for a specific table and column" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        index_names_1 = introspector.index_names(TestUser.db_table, "email")
        index_names_1.should eq ["index_app_test_users_on_email"]
      end
    end

    describe "#primary_key_constraint_names" do
      it "returns an empty array" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        introspector.primary_key_constraint_names(Post.db_table, "id").should be_empty
        introspector.primary_key_constraint_names(Post.db_table, "author_id").should be_empty
      end
    end

    describe "#table_names" do
      it "returns the table names of the associated database connection" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        introspector.table_names.should contain(TestUser.db_table)
        introspector.table_names.should_not contain("unknown_table")
      end
    end

    describe "#unique_constraint_names" do
      it "returns the unique constraint names of a specific table" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

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
