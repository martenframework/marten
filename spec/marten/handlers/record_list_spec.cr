require "./spec_helper"

describe Marten::Handlers::RecordList do
  describe "::list_context_name" do
    it "returns the configured value" do
      Marten::Handlers::RecordListSpec::TestHandler.list_context_name.should eq "users"
    end

    it "returns a default value if not configured" do
      Marten::Handlers::RecordListSpec::TestHandlerWithoutConfiguration.list_context_name.should eq "records"
    end
  end

  describe "::list_context_name(name)" do
    it "allows to configure the records list context name" do
      Marten::Handlers::RecordListSpec::TestHandler.list_context_name.should eq "users"
    end
  end

  describe "#context" do
    it "embeds the raw queryset if pagination is not used" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => user_1.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordListSpec::TestHandler.new(request, params)

      handler.context["users"].raw.should be_a Marten::DB::Query::Set(TestUser)
      handler.context["users"].to_a.should eq [user_1, user_2]
    end

    it "embeds the page resulting from the pagination if pagination is used" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => user_1.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordListSpec::TestHandlerWithPagination.new(request, params)

      handler.context["users"].raw.should be_a Marten::DB::Query::Page(TestUser)
      handler.context["users"].raw.as(Marten::DB::Query::Page(TestUser)).number.should eq 1
      handler.context["users"].to_a.should eq [user_1, user_2]
    end
  end
end

module Marten::Handlers::RecordListSpec
  class TestHandler < Marten::Handlers::RecordList
    model TestUser
    list_context_name :users
  end

  class TestHandlerWithPagination < Marten::Handlers::RecordList
    model TestUser
    list_context_name :users
    page_size 2
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::RecordList
  end
end
