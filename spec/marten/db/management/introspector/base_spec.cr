require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
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
        fk_constraint_names_1.should contain("index_app_posts_on_author_id_fk_app_test_users_id")
        fk_constraint_names_2.size.should eq 1
        fk_constraint_names_2.should contain("index_app_posts_on_updated_by_id_fk_app_test_users_id")
      {% else %}
        # SQLite
        fk_constraint_names_1.should be_empty
        fk_constraint_names_2.should be_empty
      {% end %}
    end
  end
end
