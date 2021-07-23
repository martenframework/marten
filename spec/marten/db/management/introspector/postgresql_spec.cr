require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
  describe Marten::DB::Management::Introspector::PostgreSQL do
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

    describe "#unique_constraint_names" do
      it "returns the unique constraint names of a specific table" do
        connection = Marten::DB::Connection.default
        introspector = connection.introspector

        constraint_names = [] of String

        Marten::DB::Connection.default.open do |db|
          db.query(
            <<-SQL
              SELECT c.conname
              FROM pg_constraint AS c
              JOIN pg_class AS cl ON c.conrelid = cl.oid
              WHERE cl.relname = '#{Tag.db_table}'
              AND pg_catalog.pg_table_is_visible(cl.oid) AND (c.contype = 'u' OR c.contype = 'p')
              AND 'name'=ANY(array(
                SELECT attname
                FROM unnest(c.conkey) WITH ORDINALITY cols(colid, arridx)
                JOIN pg_attribute AS ca ON cols.colid = ca.attnum
                WHERE ca.attrelid = c.conrelid
                ORDER BY cols.arridx
              ))
            SQL
          ) do |rs|
            rs.each do
              constraint_names << rs.read(String)
            end
          end
        end

        introspector.unique_constraint_names(Tag.db_table, "name").should eq constraint_names
      end
    end
  end
{% end %}
