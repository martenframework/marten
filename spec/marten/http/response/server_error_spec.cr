require "./spec_helper"

describe Marten::HTTP::Response::ServerError do
  describe "::new" do
    it "allows to initialize a 500 HTTP response" do
      response = Marten::HTTP::Response::ServerError.new
      response.status.should eq 500
    end

    it "allows to initialize other response parameters" do
      response = Marten::HTTP::Response::ServerError.new(content: "Test content", content_type: "text/plain")
      response.status.should eq 500
      response.content.should eq "Test content"
      response.content_type.should eq "text/plain"
    end
  end
end
