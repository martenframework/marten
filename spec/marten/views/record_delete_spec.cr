require "./spec_helper"

describe Marten::Views::RecordDelete do
  describe "::record_context_name" do
    it "returns the configured context name for the record" do
      Marten::Views::RecordDeleteSpec::TestView.record_context_name.should eq "test_user"
    end

    it "returns `record` by default" do
      Marten::Views::RecordDeleteSpec::TestViewWithoutConfiguration.record_context_name.should eq "record"
    end
  end

  describe "::success_route_name" do
    it "returns the configured success URL" do
      Marten::Views::RecordDeleteSpec::TestView.success_route_name.should eq "dummy"
    end

    it "returns nil by default" do
      Marten::Views::RecordDeleteSpec::TestViewWithoutConfiguration.success_route_name.should be_nil
    end
  end

  describe "::success_url" do
    it "returns the configured success URL" do
      Marten::Views::RecordDeleteSpec::TestViewWithSuccessUrl.success_url.should eq "https://example.com"
    end

    it "returns nil by default" do
      Marten::Views::RecordDeleteSpec::TestViewWithoutConfiguration.success_url.should be_nil
    end
  end

  describe "#context" do
    it "includes the record associated with the configured context name" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => user_1.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RecordDeleteSpec::TestView.new(request, params)

      view.context["test_user"].should eq user_1
    end
  end

  describe "#post" do
    it "deletes the record and returns the expected redirect" do
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
      view = Marten::Views::RecordDeleteSpec::TestView.new(request, params)

      response = view.post

      response.should be_a Marten::HTTP::Response::Found
      TestUser.get(pk: user_1.id).should be_nil
      TestUser.get(pk: user_2.id).should eq user_2
    end

    it "raises a not found error if the record is not found" do
      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => 0}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RecordDeleteSpec::TestView.new(request, params)

      expect_raises(Marten::HTTP::Errors::NotFound) { view.post }
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
      view = Marten::Views::RecordDeleteSpec::TestViewWithSuccessUrl.new(request)

      view.success_url.should eq "https://example.com"
    end

    it "returns the resolved success route if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RecordDeleteSpec::TestView.new(request)

      view.success_url.should eq Marten.routes.reverse("dummy")
    end
  end
end

module Marten::Views::RecordDeleteSpec
  class TestView < Marten::Views::RecordDelete
    model TestUser
    record_context_name "test_user"
    success_route_name "dummy"
  end

  class TestViewWithSuccessUrl < Marten::Views::RecordDelete
    model TestUser
    record_context_name "test_user"
    success_url "https://example.com"
  end

  class TestViewWithoutConfiguration < Marten::Views::RecordDelete
  end
end
