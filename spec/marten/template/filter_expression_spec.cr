require "./spec_helper"

describe Marten::Template::FilterExpression do
  describe "::new" do
    it "initializes a filter expression for a simple variable" do
      expr = Marten::Template::FilterExpression.new("foo")
      expr.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "bar"
    end

    it "initializes a filter expression for a simple variable with a single filter without arguments" do
      expr = Marten::Template::FilterExpression.new("foo|upcase")
      expr.resolve(Marten::Template::Context{"foo" => "hello"}).should eq "HELLO"
    end

    it "initializes a filter expression for a simple variable with a single filter with argument" do
      expr = Marten::Template::FilterExpression.new("foo|default:bar")
      expr.resolve(Marten::Template::Context{"foo" => nil, "bar" => 42}).should eq 42
    end

    it "initializes a filter expression with spaces between the filter name and the filter argument" do
      expr = Marten::Template::FilterExpression.new("foo | default : bar")
      expr.resolve(Marten::Template::Context{"foo" => nil, "bar" => 42}).should eq 42
    end

    it "initializes a filter expression for a simple variable with multiple filters applied" do
      expr = Marten::Template::FilterExpression.new("foo|default:bar|upcase")
      expr.resolve(Marten::Template::Context{"foo" => nil, "bar" => "hello"}).should eq "HELLO"
    end

    it "initializes a filter expression for a simple number literal" do
      expr_1 = Marten::Template::FilterExpression.new("42")
      expr_1.resolve(Marten::Template::Context{"foo" => "bar"}).should eq 42

      expr_2 = Marten::Template::FilterExpression.new("42.44")
      expr_2.resolve(Marten::Template::Context{"foo" => "bar"}).should eq 42.44
    end

    it "initializes a filter expression for a simple number literal with filters" do
      expr_1 = Marten::Template::FilterExpression.new("42 | upcase")
      expr_1.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "42"

      expr_2 = Marten::Template::FilterExpression.new("42.44|upcase")
      expr_2.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "42.44"
    end

    it "initializes a filter expression for a simple string literal" do
      expr_1 = Marten::Template::FilterExpression.new(%{"foo"})
      expr_1.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "foo"

      expr_2 = Marten::Template::FilterExpression.new(%{'foo'})
      expr_2.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "foo"

      expr_3 = Marten::Template::FilterExpression.new(%{"foo \\"bar\\""})
      expr_3.resolve(Marten::Template::Context{"foo" => "bar"}).should eq %{foo "bar"}

      expr_4 = Marten::Template::FilterExpression.new(%{'foo \\'bar\\''})
      expr_4.resolve(Marten::Template::Context{"foo" => "bar"}).should eq %{foo 'bar'}
    end

    it "initializes a filter expression for a simple string literal with filters" do
      expr_1 = Marten::Template::FilterExpression.new(%{"foo"|upcase})
      expr_1.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "FOO"

      expr_2 = Marten::Template::FilterExpression.new(%{'foo' | upcase})
      expr_2.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "FOO"

      expr_3 = Marten::Template::FilterExpression.new(%{"foo \\"bar\\"" | upcase})
      expr_3.resolve(Marten::Template::Context{"foo" => "bar"}).should eq %{FOO "BAR"}

      expr_4 = Marten::Template::FilterExpression.new(%{'foo \\'bar\\''|upcase})
      expr_4.resolve(Marten::Template::Context{"foo" => "bar"}).should eq %{FOO 'BAR'}
    end

    it "initializes a filter expression for a simple variable ending with a ? character" do
      expr = Marten::Template::FilterExpression.new("foo.bar?")
      expr.resolve(Marten::Template::Context{"foo" => {"bar?" => 42}}).should eq 42
    end

    it "raises if the raw string is not a valid filter expression" do
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Filter expression contains characters that cannot be parsed properly: test|upcase test|foo bar"
      ) do
        Marten::Template::FilterExpression.new(%{test|upcase test|foo bar})
      end
    end

    it "raises if the raw string contains an invalid variable" do
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Filter expression does not contain any variable: |test"
      ) do
        Marten::Template::FilterExpression.new("|test")
      end
    end

    it "raises if the filter expression ends with unexpected characters" do
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Filter expression ends with characters that cannot be parsed properly: foo|upcase|+"
      ) do
        Marten::Template::FilterExpression.new("foo|upcase|+")
      end
    end
  end

  describe "#resolve" do
    it "returns the expected value for a simple variable" do
      expr = Marten::Template::FilterExpression.new("foo")
      expr.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "bar"
    end

    it "returns the expected value for a simple variable with a single filter applied" do
      expr = Marten::Template::FilterExpression.new("foo|upcase")
      expr.resolve(Marten::Template::Context{"foo" => "bar"}).should eq "BAR"
    end

    it "returns the expected value for a simple variable with a multiple filters applied" do
      expr = Marten::Template::FilterExpression.new("foo|default:bar|upcase")
      expr.resolve(Marten::Template::Context{"foo" => nil, "bar" => "hello"}).should eq "HELLO"
    end

    it "returns the expected value for a variable with nested lookups" do
      expr = Marten::Template::FilterExpression.new("foo.user.first_name")
      expr.resolve(Marten::Template::Context{"foo" => {"user" => {"first_name" => "bar"}}}).should eq "bar"
    end

    it "returns the expected value for a variable with nested lookups and a single filter applied" do
      expr = Marten::Template::FilterExpression.new("foo.user.first_name | upcase")
      expr.resolve(Marten::Template::Context{"foo" => {"user" => {"first_name" => "bar"}}}).should eq "BAR"
    end

    it "returns the expected value for a variable with nested lookups and multiple filters applied" do
      expr = Marten::Template::FilterExpression.new("foo.user.first_name|default:'hello' | upcase")
      expr.resolve(Marten::Template::Context{"foo" => {"user" => {"first_name" => nil}}}).should eq "HELLO"
    end
  end
end
