require "./spec_helper"

describe Marten::Template::ContextProducer::I18n do
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

      context_producer = Marten::Template::ContextProducer::I18n.new
      context_producer.produce(request).should eq(
        {
          "available_locales" => I18n.available_locales,
          "locale"            => I18n.locale,
        }
      )
    end
  end
end
