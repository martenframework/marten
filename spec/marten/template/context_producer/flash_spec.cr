require "./spec_helper"

describe Marten::Template::ContextProducer::Flash do
  describe "#produce" do
    it "returns the expected hash when a request is present" do
      flash_store = Marten::HTTP::FlashStore.new

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
      request.flash = flash_store

      context_producer = Marten::Template::ContextProducer::Flash.new
      context_producer.produce(request).should eq({"flash" => flash_store})
    end

    it "returns nil when a request is not present" do
      context_producer = Marten::Template::ContextProducer::Flash.new
      context_producer.produce.should be_nil
    end

    it "returns nil when a request does not have a flash store set" do
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

      context_producer = Marten::Template::ContextProducer::Flash.new
      context_producer.produce(request).should be_nil
    end
  end
end
