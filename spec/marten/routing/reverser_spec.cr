require "./spec_helper"

describe Marten::Routing::Reverser do
  describe "#name" do
    it "returns the reverser path name" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.name.should eq "path:name"
    end
  end

  describe "#path_for_interpolation" do
    it "returns the reverser path for interpolation" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.path_for_interpolation.should eq "/test/%{param1}/xyz/%{param2}"
    end
  end

  describe "#parameters" do
    it "returns the reverser parameter handlers" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.parameters.should eq(
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
    end
  end

  describe "#reverse" do
    it "returns the interpolated path for matching parameters" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.reverse({param1: "hello-world", param2: 42}.to_h).should eq "/test/hello-world/xyz/42"
    end

    it "returns nil if one of the parameters is not expected by the reverser" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.reverse({unknown_param: "hello-world"}.to_h).should be_nil
    end

    it "returns nil if one of the parameters has not the expected type" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.reverse({param1: "hello-world", param2: "foobar"}.to_h).should be_nil
    end

    it "returns nil if not all expected paramters are present" do
      reverser = Marten::Routing::Reverser.new(
        "path:name",
        "/test/%{param1}/xyz/%{param2}",
        {
          "param1" => Marten::Routing::Parameter.registry["slug"],
          "param2" => Marten::Routing::Parameter.registry["int"],
        }
      )
      reverser.reverse({param1: "hello-world"}.to_h).should be_nil
    end
  end
end
