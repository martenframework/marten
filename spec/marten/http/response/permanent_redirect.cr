require "./spec_helper"

describe Marten::HTTP::Response::Redirect do
  describe "::new" do
    it "allows to initialize a 301 HTTP response by specifying the target location" do
      response = Marten::HTTP::Response::Redirect.new("https://example.com/foo/bar")
      response.status.should eq 301
      response.headers.should eq({ "Location" => "https://example.com/foo/bar" })
    end
  end
end
