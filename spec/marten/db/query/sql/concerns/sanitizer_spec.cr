require "./spec_helper"

describe Marten::DB::Query::SQL::Sanitizer do
  describe "#sanitize_positional_parameters" do
    it "sanitizes a simple query with positional parameters" do
      query = "SELECT * FROM users WHERE id = ? AND name = ?"
      params = [1, "Alice"]

      sanitizer = Marten::DB::Query::SQL::Sanitizer::Test.new
      sanitized_query, sanitized_params = sanitizer.sanitize_positional_parameters(query, params)

      sanitized_query.should eq("SELECT * FROM users WHERE id = %s AND name = %s")
      sanitized_params.should eq(params)
    end

    it "raises an error if the number of parameters does not match placeholders" do
      query = "SELECT * FROM users WHERE id = ?"
      params = [1, "Alice"] # Too many parameters

      sanitizer = Marten::DB::Query::SQL::Sanitizer::Test.new

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition) do
        sanitizer.sanitize_positional_parameters(query, params)
      end
    end

    it "uses database-specific placeholders when connection is provided" do
      query = "SELECT * FROM users WHERE id = ?"
      params = [1]

      sanitizer = Marten::DB::Query::SQL::Sanitizer::Test.new

      sanitized_query, _ = sanitizer.sanitize_positional_parameters(query, params, Marten::DB::Connection.default)

      for_postgresql { sanitized_query.should eq("SELECT * FROM users WHERE id = $1") }
      for_db_backends(:sqlite, :mysql, :mariadb) do
        sanitized_query.should eq("SELECT * FROM users WHERE id = ?")
      end
    end
  end

  describe "#sanitize_named_parameters" do
    it "sanitizes a simple query with named parameters" do
      query = "SELECT * FROM users WHERE id = :id AND name = :user_name"
      params = {"id" => 1, "user_name" => "Alice"}

      sanitizer = Marten::DB::Query::SQL::Sanitizer::Test.new
      sanitized_query, sanitized_params = sanitizer.sanitize_named_parameters(query, params)

      sanitized_query.should eq("SELECT * FROM users WHERE id = %s AND name = %s")
      sanitized_params.should eq([1, "Alice"])
    end

    it "raises an error if a named parameter is missing" do
      query = "SELECT * FROM users WHERE id = :id"
      params = {"missing" => 1}

      sanitizer = Marten::DB::Query::SQL::Sanitizer::Test.new

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition) do
        sanitizer.sanitize_named_parameters(query, params)
      end
    end

    it "uses database-specific placeholders when connection is provided" do
      query = "SELECT * FROM users WHERE id = :id"
      params = {"id" => 1}

      sanitizer = Marten::DB::Query::SQL::Sanitizer::Test.new

      sanitized_query, _ = sanitizer.sanitize_named_parameters(query, params, Marten::DB::Connection.default)

      for_postgresql { sanitized_query.should eq("SELECT * FROM users WHERE id = $1") }
      for_db_backends(:sqlite, :mysql, :mariadb) do
        sanitized_query.should eq("SELECT * FROM users WHERE id = ?")
      end
    end
  end
end

class Marten::DB::Query::SQL::Sanitizer::Test
  include Marten::DB::Query::SQL::Sanitizer
end
