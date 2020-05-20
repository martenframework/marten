require "./spec_helper"

describe Marten::HTTP::Response::Gone do
  describe "::new" do
    it "allows to initialize a 410 HTTP response" do
      response = Marten::HTTP::Response::Gone.new
      response.status.should eq 410
    end

    it "allows to initialize other response parameters" do
      response = Marten::HTTP::Response::Gone.new(content: "Test content", content_type: "text/plain")
      response.status.should eq 410
      response.content.should eq "Test content"
      response.content_type.should eq "text/plain"
    end
  end
end
