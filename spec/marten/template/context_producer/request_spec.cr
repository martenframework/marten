require "./spec_helper"

describe Marten::Template::ContextProducer::Request do
  describe "#produce" do
    it "returns the expected hash when a request is present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp",
          }
        )
      )

      context_producer = Marten::Template::ContextProducer::Request.new
      context_producer.produce(request).should eq({"request" => request})
    end

    it "returns the nil when a request is not present" do
      context_producer = Marten::Template::ContextProducer::Request.new
      context_producer.produce.should be_nil
    end
  end
end
