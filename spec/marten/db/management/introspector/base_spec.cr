require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
  describe "#model_table_names" do
    it "returns the table names associated with models that are part of installed apps" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      introspector.model_table_names.should contain(TestUser.db_table)
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

  describe "#foreign_key_constraint_names" do
    it "returns the foreign key constraint names of a specific table" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      fk_constraint_names_1 = introspector.foreign_key_constraint_names(Post.db_table, "author_id")
      fk_constraint_names_2 = introspector.foreign_key_constraint_names(Post.db_table, "updated_by_id")

      {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" || env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
        fk_constraint_names_1.size.should eq 1
        fk_constraint_names_1.should contain("index_posts_on_author_id_fk_app_test_users_id")
        fk_constraint_names_2.size.should eq 1
        fk_constraint_names_2.should contain("index_posts_on_updated_by_id_fk_app_test_users_id")
      {% else %}
        # SQLite
        fk_constraint_names_1.should be_empty
        fk_constraint_names_2.should be_empty
      {% end %}
    end
  end

  describe "#unique_constraint_names" do
    it "returns the unique constraint names of a specific table" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      constraint_names = [] of String

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
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
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
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
        {% else %}
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
        {% end %}
      end

      introspector.unique_constraint_names(Tag.db_table, "name").should eq constraint_names
    end
  end
end
