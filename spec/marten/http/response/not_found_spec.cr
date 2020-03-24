require "./spec_helper"

describe Marten::HTTP::Response::NotFound do
  describe "::new" do
    it "allows to initialize a 404 HTTP response" do
      response = Marten::HTTP::Response::NotFound.new
      response.status.should eq 404
    end

    it "allows to initialize other response parameters" do
      response = Marten::HTTP::Response::NotFound.new(content: "Test content", content_type: "text/plain")
      response.status.should eq 404
      response.content.should eq "Test content"
      response.content_type.should eq "text/plain"
    end
  end
end
