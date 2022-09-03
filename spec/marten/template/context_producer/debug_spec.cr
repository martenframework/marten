require "./spec_helper"

describe Marten::Template::ContextProducer::Debug do
  describe "#produce" do
    it "returns the expected hash" do
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

      context_producer = Marten::Template::ContextProducer::Debug.new
      context_producer.produce(request).should eq({"debug" => Marten.settings.debug})
    end
  end
end
