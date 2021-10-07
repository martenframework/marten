require "./spec_helper"

describe Marten::Views::RecordDetail do
  describe "::record_context_name" do
    it "returns the configured context name for the record" do
      Marten::Views::RecordDetailSpec::TestView.record_context_name.should eq "test_user"
    end

    it "returns `record` by default" do
      Marten::Views::RecordDetailSpec::TestViewWithoutConfiguration.record_context_name.should eq "record"
    end
  end

  describe "::record_context_name(name)" do
    it "allows to configure the context name for the record" do
      Marten::Views::RecordDetailSpec::TestView.record_context_name.should eq "test_user"
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
      view = Marten::Views::RecordDetailSpec::TestView.new(request, params)

      view.context["test_user"].should eq user_1
    end
  end
end

module Marten::Views::RecordDetailSpec
  class TestView < Marten::Views::RecordDetail
    model TestUser
    record_context_name :test_user
  end

  class TestViewWithoutConfiguration < Marten::Views::RecordDetail
  end
end
