require "./spec_helper"

for_mysql do
  describe Marten::DB::Management::Introspector::MySQL do
    describe "#foreign_key_constraint_names" do
      it "returns the foreign key constraint names of a specific table" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        fk_constraint_names_1 = introspector.foreign_key_constraint_names(Post.db_table, "author_id")
        fk_constraint_names_2 = introspector.foreign_key_constraint_names(Post.db_table, "updated_by_id")

        fk_constraint_names_1.size.should eq 1
        fk_constraint_names_1.should contain("index_posts_on_author_id_fk_app_test_users_id")
        fk_constraint_names_2.size.should eq 1
        fk_constraint_names_2.should contain("index_posts_on_updated_by_id_fk_app_test_users_id")
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

    describe "#table_names" do
      it "returns the table names of the associated database connection" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        introspector.table_names.should contain(TestUser.db_table)
        introspector.table_names.should_not contain("unknown_table")
      end
    end

    describe "#primary_key_constraint_names" do
      it "returns the primary key constraint names of a specific table and column" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        introspector.primary_key_constraint_names(Post.db_table, "id").should eq ["PRIMARY"]
        introspector.primary_key_constraint_names(Post.db_table, "author_id").should be_empty
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
              SELECT kc.constraint_name, kc.column_name
              FROM information_schema.key_column_usage AS kc, information_schema.table_constraints AS c
              WHERE kc.table_schema = DATABASE() AND kc.table_name = '#{Tag.db_table}'
              AND c.table_schema = kc.table_schema
              AND c.table_name = kc.table_name
              AND c.constraint_name = kc.constraint_name
              AND (c.constraint_type = 'PRIMARY KEY' OR c.constraint_type = 'UNIQUE')
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              constraint_name = rs.read(String)
              constraint_names << constraint_name if column_name == "name"
            end
          end
        end

        introspector.unique_constraint_names(Tag.db_table, "name").should eq constraint_names
      end
    end
  end
end
