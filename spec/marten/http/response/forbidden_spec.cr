require "./spec_helper"

describe Marten::HTTP::Response::Forbidden do
  describe "::new" do
    it "allows to initialize a 403 HTTP response" do
      response = Marten::HTTP::Response::Forbidden.new
      response.status.should eq 403
    end

    it "allows to initialize other response parameters" do
      response = Marten::HTTP::Response::Forbidden.new(content: "Test content", content_type: "text/plain")
      response.status.should eq 403
      response.content.should eq "Test content"
      response.content_type.should eq "text/plain"
    end
  end
end
