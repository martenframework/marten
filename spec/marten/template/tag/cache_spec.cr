require "./spec_helper"

describe Marten::Template::Tag::Cache do
  around_each do |t|
    with_overridden_setting("cache_store", Marten::Cache::Store::Memory.new) do
      t.run
    end
  end

  describe "::new" do
    it "can initialize a regular cache tag as expected" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache "mykey" 3600})

      time_now = Time.local

      Timecop.freeze(time_now) do
        tag.render(Marten::Template::Context{"var" => Time.local}).should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 30.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local}).should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 90.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local}).should eq(
          "Cached content: #{(time_now + 90.minutes)}"
        )
      end
    end

    it "can initialize a regular cache tag with vary on arguments as expected" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache "mykey" 3600 foo_var bar_var})

      time_now = Time.local

      Timecop.freeze(time_now) do
        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo1", "bar_var" => "bar1"})
          .should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 30.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo1", "bar_var" => "bar1"})
          .should eq "Cached content: #{time_now}"

        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo2", "bar_var" => "bar1"})
          .should eq "Cached content: #{(time_now + 30.minutes)}"
      end

      Timecop.freeze(time_now + 92.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo1", "bar_var" => "bar1"})
          .should eq "Cached content: #{(time_now + 92.minutes)}"

        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo2", "bar_var" => "bar1"})
          .should eq "Cached content: #{(time_now + 92.minutes)}"
      end
    end

    it "raises if it called with less than two arguments" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed cache tag: at least two arguments must be provided"
      ) do
        Marten::Template::Tag::Cache.new(parser, %{cache "mykey"})
      end
    end
  end

  describe "#render" do
    it "caches the content as expected when no vary on arguments are used" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache "mykey" 3600})

      time_now = Time.local

      Timecop.freeze(time_now) do
        tag.render(Marten::Template::Context{"var" => Time.local}).should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 30.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local}).should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 90.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local}).should eq(
          "Cached content: #{(time_now + 90.minutes)}"
        )
      end
    end

    it "caches the content as expected when vary on arguments are used" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache "mykey" 3600 foo_var bar_var})

      time_now = Time.local

      Timecop.freeze(time_now) do
        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo1", "bar_var" => "bar1"})
          .should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 30.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo1", "bar_var" => "bar1"})
          .should eq "Cached content: #{time_now}"

        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo2", "bar_var" => "bar1"})
          .should eq "Cached content: #{(time_now + 30.minutes)}"
      end

      Timecop.freeze(time_now + 92.minutes) do
        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo1", "bar_var" => "bar1"})
          .should eq "Cached content: #{(time_now + 92.minutes)}"

        tag.render(Marten::Template::Context{"var" => Time.local, "foo_var" => "foo2", "bar_var" => "bar1"})
          .should eq "Cached content: #{(time_now + 92.minutes)}"
      end
    end

    it "properly resolves the cache key variable" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache key 3600})

      time_now = Time.local

      Timecop.freeze(time_now) do
        tag.render(Marten::Template::Context{"key" => "mykey", "var" => Time.local})
          .should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 30.minutes) do
        tag.render(Marten::Template::Context{"key" => "mykey", "var" => Time.local})
          .should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 90.minutes) do
        tag.render(Marten::Template::Context{"key" => "mykey", "var" => Time.local})
          .should eq("Cached content: #{(time_now + 90.minutes)}")
      end
    end

    it "properly resolves the expiry variable" do
      parser = Marten::Template::Parser.new("Cached content: {{ var }}{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache "mykey" expiry})

      time_now = Time.local

      Timecop.freeze(time_now) do
        tag.render(Marten::Template::Context{"expiry" => 3600, "var" => Time.local})
          .should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 30.minutes) do
        tag.render(Marten::Template::Context{"expiry" => 3600, "var" => Time.local})
          .should eq "Cached content: #{time_now}"
      end

      Timecop.freeze(time_now + 90.minutes) do
        tag.render(Marten::Template::Context{"expiry" => 3600, "var" => Time.local})
          .should eq("Cached content: #{(time_now + 90.minutes)}")
      end
    end

    it "raises if the expiry is not an integer value" do
      parser = Marten::Template::Parser.new("Cached content!{% endcache %}")
      tag = Marten::Template::Tag::Cache.new(parser, %{cache "mykey" expiry})

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Invalid cache timeout value: got a non-integer value ('not an integer')"
      ) do
        tag.render(Marten::Template::Context{"expiry" => "not an integer"})
      end
    end
  end
end
