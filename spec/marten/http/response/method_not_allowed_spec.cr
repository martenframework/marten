require "./spec_helper"

describe Marten::HTTP::Response::MethodNotAllowed do
  describe "::new" do
    it "allows to initialize a 405 HTTP response by specifying allowed methods" do
      response = Marten::HTTP::Response::MethodNotAllowed.new(%w(GET POST))
      response.status.should eq 405
      response.headers.should eq(Marten::HTTP::Headers{"Allow" => "GET, POST"})
    end

    it "allows to initialize other response parameters" do
      response = Marten::HTTP::Response::MethodNotAllowed.new(
        %w(GET POST),
        content: "Test content",
        content_type: "text/plain"
      )
      response.status.should eq 405
      response.headers.should eq(Marten::HTTP::Headers{"Allow" => "GET, POST"})
      response.content.should eq "Test content"
      response.content_type.should eq "text/plain"
    end
  end
end
