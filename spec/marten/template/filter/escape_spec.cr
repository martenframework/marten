require "./spec_helper"

describe Marten::Template::Filter::Escape do
  describe "#apply" do
    it "returns the HTML escaped version of the string" do
      filter = Marten::Template::Filter::Escape.new
      filter.apply(Marten::Template::Value.from("<b>Let's do it</b>"))
        .should eq "&lt;b&gt;Let&#39;s do it&lt;/b&gt;"
      filter.apply(Marten::Template::Value.from("\"Tom\" & \"Jerry\""))
        .should eq "&quot;Tom&quot; &amp; &quot;Jerry&quot;"
    end

    it "returns safe strings" do
      filter = Marten::Template::Filter::Escape.new
      filter.apply(Marten::Template::Value.from("<b>Let's do it</b>")).raw.should be_a Marten::Template::SafeString
    end
  end
end
