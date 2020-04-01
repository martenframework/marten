require "./spec_helper"

describe Marten::HTTP::Response::BadRequest do
  describe "::new" do
    it "allows to initialize a 400 HTTP response" do
      response = Marten::HTTP::Response::BadRequest.new
      response.status.should eq 400
    end

    it "allows to initialize other response parameters" do
      response = Marten::HTTP::Response::BadRequest.new(content: "Test content", content_type: "text/plain")
      response.status.should eq 400
      response.content.should eq "Test content"
      response.content_type.should eq "text/plain"
    end
  end
end
