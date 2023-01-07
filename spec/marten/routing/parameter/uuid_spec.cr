require "./spec_helper"

describe Marten::Routing::Parameter::UUID do
  describe "#regex" do
    it "returns the regex used to identify UUID parameters" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.regex.should eq /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
    end

    it "matches valid path UUIDs" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.regex.match(::UUID.random.to_s).should be_truthy
      parameter.regex.match("a288e10f-fffe-46d1-b71a-436e9190cdc3").should be_truthy
    end

    it "does not match invalid path UUIDs" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.regex.match("foo").should be_falsey
      parameter.regex.match("a288e10f-fffe-46d1-b71a-436e9190cdc").should be_falsey
    end
  end

  describe "#loads" do
    it "loads a UUID parameter" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.loads("a288e10f-fffe-46d1-b71a-436e9190cdc3").should be_a ::UUID
      parameter.loads("a288e10f-fffe-46d1-b71a-436e9190cdc3").should(
        eq(::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3"))
      )
    end

    it "returns nil if the input is not a UUID" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.dumps({foo: "bar"}).should be_nil
    end
  end

  describe "#dumps" do
    it "dumps a UUID parameter" do
      uuid = ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3")
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.dumps(uuid).should eq "a288e10f-fffe-46d1-b71a-436e9190cdc3"
    end

    it "dumps a UUID string" do
      uuid = ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3")
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.dumps(uuid.to_s).should eq "a288e10f-fffe-46d1-b71a-436e9190cdc3"
    end

    it "returns nil if the passed string does not correspond to a valid UUID" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.dumps("bad").should be_nil
    end

    it "returns nil for other values" do
      parameter = Marten::Routing::Parameter::UUID.new
      parameter.dumps(42).should be_nil
    end
  end
end
