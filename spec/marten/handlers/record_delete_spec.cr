require "./spec_helper"

describe Marten::Handlers::RecordDelete do
  describe "::record_context_name" do
    it "returns the configured context name for the record" do
      Marten::Handlers::RecordDeleteSpec::TestHandler.record_context_name.should eq "test_user"
    end

    it "returns `record` by default" do
      Marten::Handlers::RecordDeleteSpec::TestHandlerWithoutConfiguration.record_context_name.should eq "record"
    end
  end

  describe "::success_route_name" do
    it "returns the configured success URL" do
      Marten::Handlers::RecordDeleteSpec::TestHandler.success_route_name.should eq "dummy"
    end

    it "returns nil by default" do
      Marten::Handlers::RecordDeleteSpec::TestHandlerWithoutConfiguration.success_route_name.should be_nil
    end
  end

  describe "::success_url" do
    it "returns the configured success URL" do
      Marten::Handlers::RecordDeleteSpec::TestHandlerWithSuccessUrl.success_url.should eq "https://example.com"
    end

    it "returns nil by default" do
      Marten::Handlers::RecordDeleteSpec::TestHandlerWithoutConfiguration.success_url.should be_nil
    end
  end

  describe "#post" do
    it "deletes the record and returns the expected redirect" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      params = Marten::Routing::MatchParameters{"pk" => user_1.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordDeleteSpec::TestHandler.new(request, params)

      response = handler.post

      response.should be_a Marten::HTTP::Response::Found
      TestUser.get(pk: user_1.id).should be_nil
      TestUser.get(pk: user_2.id).should eq user_2
    end

    it "raises a not found error if the record is not found" do
      params = Marten::Routing::MatchParameters{"pk" => 0}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordDeleteSpec::TestHandler.new(request, params)

      expect_raises(Marten::HTTP::Errors::NotFound) { handler.post }
    end
  end

  describe "#render_to_response" do
    it "includes the record associated with the configured context name in the global context" do
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
      handler = Marten::Handlers::RecordDeleteSpec::TestHandler.new(request, params)

      handler.render_to_response(context: nil)

      handler.context["test_user"].should eq user_1
    end
  end

  describe "#success_url" do
    it "returns the raw success URL if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordDeleteSpec::TestHandlerWithSuccessUrl.new(request)

      handler.success_url.should eq "https://example.com"
    end

    it "returns the resolved success route if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordDeleteSpec::TestHandler.new(request)

      handler.success_url.should eq Marten.routes.reverse("dummy")
    end
  end
end

module Marten::Handlers::RecordDeleteSpec
  class TestHandler < Marten::Handlers::RecordDelete
    model TestUser
    record_context_name "test_user"
    success_route_name "dummy"
    template_name "specs/handlers/template/test.html"
  end

  class TestHandlerWithSuccessUrl < Marten::Handlers::RecordDelete
    model TestUser
    record_context_name "test_user"
    success_url "https://example.com"
    template_name "specs/handlers/template/test.html"
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::RecordDelete
  end
end
