require "./spec_helper"

describe Marten::HTTP::Response::SeeOther do
  describe "::new" do
    it "allows to initialize a 303 HTTP response by specifying the target location" do
      response = Marten::HTTP::Response::SeeOther.new("https://example.com/foo/bar")
      response.status.should eq 303
      response.headers.should eq(Marten::HTTP::Headers{"Location" => "https://example.com/foo/bar"})
    end
  end
end
