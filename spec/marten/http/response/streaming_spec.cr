require "./spec_helper"

describe Marten::HTTP::Response::Streaming do
  describe "::new" do
    it "allows to initialize a streaming content from an iterator of string, a content type, and a status code" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each, content_type: "text/csv", status: 204)

      response.streamed_content.to_a.should eq ["foo", "bar"]
      response.content_type.should eq "text/csv"
      response.status.should eq 204
    end

    it "sets the response content type to text/html if it is not specified" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each)
      response.content_type.should eq "text/html"
    end

    it "sets the status code to 200 if it is not specified" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each)
      response.status.should eq 200
    end
  end

  describe "#content" do
    it "raises NotImplementedError" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each)

      expect_raises(NotImplementedError) { response.content }
    end
  end

  describe "#content=" do
    it "raises NotImplementedError" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each)

      expect_raises(NotImplementedError) { response.content = "xyz" }
    end
  end

  describe "#streamed_content" do
    it "returns the streamed content iterator" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each)

      response.streamed_content.to_a.should eq ["foo", "bar"]
    end
  end

  describe "#streamed_content=" do
    it "allows to set the streamed content iterator" do
      response = Marten::HTTP::Response::Streaming.new(["foo", "bar"].each)
      response.streamed_content = ["xyz", "test"].each

      response.streamed_content.to_a.should eq ["xyz", "test"]
    end
  end
end
