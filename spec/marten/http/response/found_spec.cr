require "./spec_helper"

describe Marten::HTTP::Response::Found do
  describe "::new" do
    it "allows to initialize a 302 HTTP response by specifying the target location" do
      response = Marten::HTTP::Response::Found.new("https://example.com/foo/bar")
      response.status.should eq 302
      response.headers.should eq(Marten::HTTP::Headers{"Location" => "https://example.com/foo/bar"})
    end
  end
end
