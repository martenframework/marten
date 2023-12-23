require "./spec_helper"

describe Marten::Handlers::RecordDetail do
  describe "::record_context_name" do
    it "returns the configured context name for the record" do
      Marten::Handlers::RecordDetailSpec::TestHandler.record_context_name.should eq "test_user"
    end

    it "returns `record` by default" do
      Marten::Handlers::RecordDetailSpec::TestHandlerWithoutConfiguration.record_context_name.should eq "record"
    end
  end

  describe "::record_context_name(name)" do
    it "allows to configure the context name for the record" do
      Marten::Handlers::RecordDetailSpec::TestHandler.record_context_name.should eq "test_user"
    end
  end

  describe "#render_to_response" do
    it "includes the record associated with the configured context name into the global context" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      params = Marten::Routing::MatchParameters{"pk" => user_1.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordDetailSpec::TestHandler.new(request, params)
      handler.render_to_response(context: nil)

      handler.context["test_user"].should eq user_1
    end
  end
end

module Marten::Handlers::RecordDetailSpec
  class TestHandler < Marten::Handlers::RecordDetail
    model TestUser
    record_context_name :test_user
    template_name "specs/handlers/template/test.html"
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::RecordDetail
  end
end
