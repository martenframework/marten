require "./spec_helper"
require "./querying_spec/app"

describe Marten::DB::Model::Querying do
  describe "::all" do
    it "returns a queryset containing all the objects matched by the default scope" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      qs = TestUser.all
      qs.should be_a(Marten::DB::Query::Set(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "foo")).should be_true
    end

    it "returns a queryset containing all the objects matched by a custom default scope if applicable" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)

      qs = Tag.all
      qs.should be_a(Marten::DB::Query::Set(Tag))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(Tag.get!(name: "crystal")).should be_true
      results.includes?(Tag.get!(name: "coding")).should be_true
    end
  end

  describe "::annotate" do
    it "returns a new query set with the specified annotations" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Example post 1", score: 5.0)
      Post.create!(author: user_1, title: "Example post 2", score: 5.0)
      Post.create!(author: user_3, title: "Example post 3", score: 5.0)

      qset = TestUser.annotate { count(:posts) }.order("-posts_count")

      qset.to_a.should eq [user_1, user_3, user_2]
      qset[0].annotations["posts_count"].should eq 2
      qset[1].annotations["posts_count"].should eq 1
      qset[2].annotations["posts_count"].should eq 0
    end
  end

  describe "::any?" do
    it "returns true if the default queryset matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Tag.any?.should be_true # ameba:disable Performance/AnyInsteadOfPresent
    end

    it "returns false if the queryset doesn't match at least one record" do
      Tag.any?.should be_false # ameba:disable Performance/AnyInsteadOfPresent
    end
  end

  describe "::average" do
    it "properly calculates the average" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post 1", score: 5.0)
      Post.create!(author: user, title: "Example post 2", score: 5.0)

      Post.average(:score).not_nil!.should be_close(5.0, 0.00001)
    end
  end

  describe "::bulk_create" do
    it "allows to insert an array of records without specifying a batch size" do
      objects = (1..100).map do |i|
        Tag.new(name: "tag #{i}", is_active: true)
      end

      inserted_objects = Tag.bulk_create(objects)

      inserted_objects.size.should eq objects.size
      Tag.filter(name__in: objects.map(&.name)).count.should eq objects.size
    end

    it "allows to insert a small array of records while specifying a batch size" do
      objects = (1..100).map do |i|
        Tag.new(name: "tag #{i}", is_active: true)
      end

      inserted_objects = Tag.bulk_create(objects, batch_size: 10)

      inserted_objects.size.should eq objects.size
      Tag.filter(name__in: objects.map(&.name)).count.should eq objects.size
    end
  end

  describe "::count" do
    it "returns the expected number of records when no field is specified" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Tag.count.should eq 3
    end

    it "returns the expected number of records when a field is specified as a symbol" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post 1", updated_by: user)
      Post.create!(author: user, title: "Example post 2", updated_by: user)
      Post.create!(author: user, title: "Example post 3")

      Post.count(:title).should eq 3
      Post.count(:updated_by).should eq 2
    end

    it "returns the expected number of records when a field is specified as a string" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post 1", updated_by: user)
      Post.create!(author: user, title: "Example post 2", updated_by: user)
      Post.create!(author: user, title: "Example post 3")

      Post.count("title").should eq 3
      Post.count("updated_by").should eq 2
    end
  end

  describe "::default_queryset" do
    it "returns a queryset containing all the objects by default" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      qs = TestUser.default_queryset
      qs.should be_a(Marten::DB::Query::Set(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "foo")).should be_true
    end
  end

  describe "::default_scope" do
    with_installed_apps Marten::DB::Model::QueryingSpec::App

    it "allows to define a default scope for a model" do
      post_1 = Marten::DB::Model::QueryingSpec::PostWithDefaultScope.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      Marten::DB::Model::QueryingSpec::PostWithDefaultScope.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::PostWithDefaultScope.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::PostWithDefaultScope.all.to_a.should eq [post_1, post_3]
    end

    it "allows to define a default scope for a model through the use of an abstract parent model" do
      post_1 = Marten::DB::Model::QueryingSpec::NonAbstractPostWithDefaultScope.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      Marten::DB::Model::QueryingSpec::NonAbstractPostWithDefaultScope.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::NonAbstractPostWithDefaultScope.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::NonAbstractPostWithDefaultScope.all.to_a.should eq [post_1, post_3]
    end

    it "allows to define a default scope for a model through the use of a non-abstract parent model" do
      post_1 = Marten::DB::Model::QueryingSpec::ChildPostWithDefaultScope.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      Marten::DB::Model::QueryingSpec::ChildPostWithDefaultScope.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::ChildPostWithDefaultScope.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::ChildPostWithDefaultScope.all.to_a.should eq [post_1, post_3]
    end
  end

  describe "::exclude" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns a queryset without the objects matching the excluding predicates" do
      qs = TestUser.exclude(username: "foo")
      qs.should be_a(Marten::DB::Query::Set(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "jd2")).should be_true
    end

    it "makes use of the default queryset" do
      qs = Tag.exclude(name: "coding")
      qs.should be_a(Marten::DB::Query::Set(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "crystal")
    end

    it "returns a queryset without the objects matching the advanced predicates expression" do
      qs = TestUser.exclude { q(username: "foo") | q(username: "jd1") }
      qs.should be_a(Marten::DB::Query::Set(TestUser))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq TestUser.get(username: "jd2")
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      qs = Tag.exclude { q(name: "crystal") | q(name: "coding") }
      qs.should be_a(Marten::DB::Query::Set(Tag))

      results = qs.to_a
      results.size.should eq 0
    end
  end

  describe "::exists?" do
    it "returns true if the default queryset matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Tag.exists?.should be_true
    end

    it "returns false if the queryset doesn't match at least one record" do
      Tag.exists?.should be_false
    end

    it "returns true if the specified filters matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Tag.exists?(name: "crystal").should be_true
    end

    it "returns false if the specified filters does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Tag.exists?(name: "ruby").should be_false
    end

    it "returns true if the passed q() expression matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Tag.exists? { q(name: "crystal") }.should be_true
    end

    it "returns false if the passed q() expression does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Tag.exists? { q(name: "ruby") }.should be_false
    end
  end

  describe "::filter" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns a queryset with the objects matching the filter predicates" do
      qs = TestUser.filter(username__startswith: "jd")
      qs.should be_a(Marten::DB::Query::Set(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "jd2")).should be_true
    end

    it "makes use of the default queryset" do
      qs = Tag.filter(name: "coding")
      qs.should be_a(Marten::DB::Query::Set(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "coding")
    end

    it "returns a queryset with the objects matching the advanced predicates expression" do
      qs = TestUser.filter { q(username: "foo") | q(username: "jd1") }
      qs.should be_a(Marten::DB::Query::Set(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "foo")).should be_true
      results.includes?(TestUser.get!(username: "jd1")).should be_true
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      qs = Tag.filter { q(name__startswith: "cr") & q(name__endswith: "al") }
      qs.should be_a(Marten::DB::Query::Set(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "crystal")
    end

    it "allows filtering records by providing a single raw predicate" do
      TestUser.filter("username = 'jd1'").to_a.should eq [TestUser.get!(username: "jd1")]
    end

    it "allows filtering records by providing a raw predicate and positional parameters" do
      TestUser.filter("username = ?", "jd1").to_a.should eq [TestUser.get!(username: "jd1")]
    end

    it "allows filtering records by providing a raw predicate and named parameters" do
      TestUser.filter("username = :username", username: "jd1").to_a.should eq [TestUser.get!(username: "jd1")]
    end

    it "allows filtering records by providing a raw predicate and an array of positional parameters" do
      TestUser.filter("username = ?", ["jd1"]).to_a.should eq [TestUser.get!(username: "jd1")]
    end

    it "allows filtering records by providing a raw predicate and a hash of named parameters" do
      TestUser.filter("username = :username", {"username" => "jd1"}).to_a.should eq [TestUser.get!(username: "jd1")]
    end

    it "allows filtering records by providing a raw predicate and a named tuple of named parameters" do
      TestUser.filter("username = :username", {username: "jd1"}).to_a.should eq [TestUser.get!(username: "jd1")]
    end
  end

  describe "::first" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the first object" do
      TestUser.first.should eq TestUser.get!(username: "jd1")
    end

    it "makes use of the default queryset" do
      Tag.first.should eq Tag.get!(name: "ruby")
    end
  end

  describe "::first!" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the first object" do
      TestUser.first!.should eq TestUser.get!(username: "jd1")
    end

    it "makes use of the default queryset" do
      Tag.first!.should eq Tag.get!(name: "ruby")
    end

    it "raises a NilAssertionError if no record is found" do
      Tag.all.delete
      expect_raises(NilAssertionError) { Tag.first! }
    end
  end

  describe "::get" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the object corresponding to the passed simple predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get(username: "jd3").should eq user
    end

    it "returns nil if the object does not exist" do
      TestUser.get(username: "unknown").should be_nil
    end

    it "raises if multiple records match the given predicates" do
      expect_raises(Marten::DB::Errors::MultipleRecordsFound) { TestUser.get(username__startswith: "jd") }
    end

    it "makes use of the default queryset" do
      tag = Tag.create!(name: "verbose", is_active: true)
      Tag.get(name: "verbose").should eq tag
      Tag.get(name: "crystal").should be_nil
    end

    it "returns the object matching the advanced predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get { q(username__startswith: "jd") & q(username__endswith: "3") }.should eq user
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      Tag.get { q(name: "crystal") }.should be_nil
    end

    it "returns the object corresponding to the raw SQL predicate" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get("username = 'jd3'").should eq user
    end

    it "returns the object corresponding to the raw SQL predicate with positional arguments" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get("username = ?", "jd3").should eq user
    end

    it "returns nil if no record matches the raw SQL predicate with positional arguments" do
      TestUser.get("username = ?", "unknown").should be_nil
    end

    it "returns the object when parameters are passed as an array" do
      tag = Tag.create!(name: "elixir", is_active: true)
      Tag.get("name = ? AND is_active = ?", ["elixir", true]).should eq tag
    end

    it "returns nil when no record matches and parameters are passed as an array" do
      Tag.get("name = ? AND is_active = ?", ["nonexistent", true]).should be_nil
    end

    it "raises an error for an invalid SQL column in raw predicate" do
      expect_raises(Exception) { TestUser.get("invalid_column = ?", "jd1") }
    end

    it "returns the object using a raw SQL predicate with named parameters" do
      tag = Tag.create!(name: "custom", is_active: true)
      Tag.get("name = :name AND is_active = :active", name: "custom", active: true).should eq tag
    end

    it "returns nil if no record matches the raw SQL predicate with named parameters" do
      Tag.get("name = :name AND is_active = :active", name: "nonexistent", active: false).should be_nil
    end

    it "returns the object when parameters are passed as a named tuple" do
      tag = Tag.create!(name: "rust", is_active: true)
      Tag.get("name = :name AND is_active = :active", {name: "rust", active: true}).should eq tag
    end

    it "returns nil when no record matches and parameters are passed as a named tuple" do
      Tag.get("name = :name AND is_active = :active", {name: "nonexistent", active: false}).should be_nil
    end

    it "returns the object when parameters are passed as a hash" do
      tag = Tag.create!(name: "python", is_active: true)
      Tag.get("name = :name AND is_active = :active", {"name" => "python", "active" => true}).should eq tag
    end

    it "returns nil when no record matches and parameters are passed as a hash" do
      Tag.get("name = :name AND is_active = :active", {"name" => "nonexistent", "active" => false}).should be_nil
    end
  end

  describe "::get!" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the object corresponding to the passed simple predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get!(username: "jd3").should eq user
    end

    it "raises if the record is not found" do
      expect_raises(Marten::DB::Errors::RecordNotFound) { TestUser.get!(username: "unknown") }
    end

    it "raises if multiple records match the given predicates" do
      expect_raises(Marten::DB::Errors::MultipleRecordsFound) { TestUser.get!(username__startswith: "jd") }
    end

    it "makes use of the default queryset" do
      tag = Tag.create!(name: "verbose", is_active: true)
      Tag.get!(name: "verbose").should eq tag
      expect_raises(Marten::DB::Errors::RecordNotFound) { Tag.get!(name: "crystal") }
    end

    it "returns the object matching the advanced predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get! { q(username__startswith: "jd") & q(username__endswith: "3") }.should eq user
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      expect_raises(Marten::DB::Errors::RecordNotFound) { Tag.get! { q(name: "crystal") } }
    end

    it "returns the object using a raw SQL predicate" do
      tag = Tag.create!(name: "elixir", is_active: true)
      Tag.get!("name = 'elixir' AND is_active = true").should eq tag
    end

    it "raises RecordNotFound when no record matches" do
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        Tag.get!("name = 'nonexistent' AND is_active = true")
      end
    end

    it "returns the object using a raw SQL predicate with positional arguments" do
      tag = Tag.create!(name: "elixir", is_active: true)
      Tag.get!("name = ? AND is_active = ?", "elixir", true).should eq tag
    end

    it "raises RecordNotFound when no record matches with positional arguments" do
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        Tag.get!("name = ? AND is_active = ?", "nonexistent", true)
      end
    end

    it "returns the object using a raw SQL predicate with named arguments" do
      tag = Tag.create!(name: "python", is_active: true)
      Tag.get!("name = :name AND is_active = :active", name: "python", active: true).should eq tag
    end

    it "raises RecordNotFound when no record matches with named arguments" do
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        Tag.get!("name = :name AND is_active = :active", name: "nonexistent", active: false)
      end
    end

    it "returns the object when parameters are passed as an array" do
      tag = Tag.create!(name: "elixir", is_active: true)
      Tag.get!("name = ? AND is_active = ?", ["elixir", true]).should eq tag
    end

    it "raises RecordNotFound when no record matches and parameters are passed as an array" do
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        Tag.get!("name = ? AND is_active = ?", ["nonexistent", true])
      end
    end

    it "returns the object when parameters are passed as a named tuple" do
      tag = Tag.create!(name: "rust", is_active: true)
      Tag.get!("name = :name AND is_active = :active", {name: "rust", active: true}).should eq tag
    end

    it "raises RecordNotFound when no record matches and parameters are passed as a named tuple" do
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        Tag.get!("name = :name AND is_active = :active", {name: "nonexistent", active: false})
      end
    end

    it "returns the object when parameters are passed as a hash" do
      tag = Tag.create!(name: "rust", is_active: true)
      Tag.get!("name = :name AND is_active = :active", {"name" => "rust", "active" => true}).should eq tag
    end

    it "raises RecordNotFound when no record matches and parameters are passed as a hash" do
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        Tag.get!("name = :name AND is_active = :active", {"name" => "nonexistent", "active" => false})
      end
    end
  end

  describe "::get_or_create" do
    it "returns the record matched by the specified arguments" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Tag.get_or_create(name: "crystal").should eq tag
      Tag.all.size.should eq 2
    end

    it "creates a record using the specified arguments if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      new_tag = Tag.get_or_create(name: "newtag", is_active: true)
      new_tag.persisted?.should be_true

      Tag.all.size.should eq 3
    end

    it "creates a record using the specified arguments and the specified block if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      new_tag = Tag.get_or_create(name: "newtag") do |t|
        t.is_active = true
      end

      new_tag.persisted?.should be_true

      Tag.all.size.should eq 3
    end

    it "initializes a record but does not save it if it is invalid when no other record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      new_tag = Tag.get_or_create(name: "newtag")
      new_tag.valid?.should be_false
      new_tag.persisted?.should be_false

      Tag.all.size.should eq 2
    end

    it "initializes a record but does not save it if it is invalid when no other record is found and a block is used" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      new_tag = Tag.get_or_create(name: "newtag") do |r|
        r.is_active = nil
      end

      new_tag.valid?.should be_false
      new_tag.persisted?.should be_false

      Tag.all.size.should eq 2
    end

    it "raises if multiple records are found when using predicates expressed as keyword arguments" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "John", last_name: "Doe")

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        TestUser.get_or_create(email: "jd@example.com")
      end
    end
  end

  describe "#get_or_create!" do
    it "returns the record matched by the specified arguments" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Tag.get_or_create!(name: "crystal").should eq tag
      Tag.all.size.should eq 2
    end

    it "creates a record using the specified arguments if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      new_tag = Tag.get_or_create!(name: "newtag", is_active: true)
      new_tag.persisted?.should be_true

      Tag.all.size.should eq 3
    end

    it "creates a record using the specified arguments and the specified block if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      new_tag = Tag.get_or_create!(name: "newtag") do |t|
        t.is_active = true
      end

      new_tag.persisted?.should be_true

      Tag.all.size.should eq 3
    end

    it "raises if the new record is invalid when no other record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Tag.get_or_create!(name: "newtag")
      end

      Tag.all.size.should eq 2
    end

    it "raises if the new record is invalid when no other record is found and a block is used" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Tag.get_or_create!(name: "newtag") do |r|
          r.is_active = nil
        end
      end

      Tag.all.size.should eq 2
    end

    it "raises if multiple records are found when using predicates expressed as keyword arguments" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "John", last_name: "Doe")

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        TestUser.get_or_create!(email: "jd@example.com")
      end
    end
  end

  describe "::join" do
    it "allows to configure joins for a specific relation" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post")
      Post.join(:author).query.joins?.should be_true
    end
  end

  describe "::maximum" do
    it "retrieves the post with the highest score" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post 1", score: 20.0)
      Post.create!(author: user, title: "Example post 2", score: 5.0)

      Post.maximum(:score).should eq 20.0
    end
  end

  describe "::minimum" do
    it "retrieves the post with the lowest score" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post 1", score: 20.0)
      Post.create!(author: user, title: "Example post 2", score: 5.0)

      Post.minimum(:score).should eq 5.0
    end
  end

  describe "::last" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: false)
    end

    it "returns the last object" do
      TestUser.last.should eq TestUser.get!(username: "foo")
    end

    it "makes use of the default queryset" do
      Tag.last.should eq Tag.get!(name: "coding")
    end
  end

  describe "::last!" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: false)
    end

    it "returns the last object" do
      TestUser.last!.should eq TestUser.get!(username: "foo")
    end

    it "makes use of the default queryset" do
      Tag.last!.should eq Tag.get!(name: "coding")
    end

    it "raises a NilAssertionError error if no record is found" do
      Tag.all.delete
      expect_raises(NilAssertionError) { Tag.last! }
    end
  end

  describe "::limit" do
    it "allows to limit the number of records returned" do
      tag_1 = Tag.create!(name: "tag-1", is_active: true)
      tag_2 = Tag.create!(name: "tag-2", is_active: true)
      Tag.create!(name: "tag-3", is_active: true)

      Tag.limit(2).to_a.should eq [tag_1, tag_2]
    end
  end

  describe "::offset" do
    it "allows to offset the records returned" do
      Tag.create!(name: "tag-1", is_active: true)
      tag_2 = Tag.create!(name: "tag-2", is_active: true)
      tag_3 = Tag.create!(name: "tag-3", is_active: true)

      Tag.offset(1).to_a.should eq [tag_2, tag_3]
    end
  end

  describe "::order" do
    it "allows to order using a specific column specified as a string" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      Tag.order("name").to_a.should eq [tag_2, tag_3, tag_1]
      Tag.order("-name").to_a.should eq [tag_1, tag_3, tag_2]
    end

    it "allows to order using a specific column specified as a symbol" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      Tag.order(:name).to_a.should eq [tag_2, tag_3, tag_1]
      Tag.order(:"-name").to_a.should eq [tag_1, tag_3, tag_2]
    end

    it "allows to order using multiple columns" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      TestUser.order(:first_name, :last_name).to_a.should eq [user_3, user_2, user_1]
    end

    it "allows to order from an array of strings" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      TestUser.order(["first_name", "last_name"]).to_a.should eq [user_3, user_2, user_1]
    end

    it "allows to order from an array of symbols" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      TestUser.order([:first_name, :last_name]).to_a.should eq [user_3, user_2, user_1]
    end
  end

  describe "::pks" do
    it "extracts the primary keys of the records matched by the default query set" do
      test_user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      test_user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      test_user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      TestUser.pks.should eq [test_user_1.pk, test_user_2.pk, test_user_3.pk]
    end
  end

  describe "::pluck" do
    context "with double splat arguments" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.pluck(:username).should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.pluck("username").should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting multiple specific fields values" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.pluck(:first_name, :last_name).should eq [["John", "Doe"], ["John", "Doe"], ["Bob", "Doe"]]
      end

      it "allows extracting specific fields by following associations" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        Post.create!(author: user_1, title: "Post 1", published: true)
        Post.create!(author: user_1, title: "Post 2", published: true)
        Post.create!(author: user_2, title: "Post 3", published: true)
        Post.create!(author: user_1, title: "Post 4", published: false)
        Post.create!(author: user_3, title: "Post 5", published: false)

        Post.pluck(:title, :author__first_name).to_set.should eq(
          [["Post 1", "John"], ["Post 2", "John"], ["Post 3", "John"], ["Post 4", "John"], ["Post 5", "Bob"]].to_set
        )
      end
    end

    context "with array of field names" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.pluck([:username]).should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.pluck(["username"]).should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting multiple specific fields values" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.pluck([:first_name, :last_name]).should eq [["John", "Doe"], ["John", "Doe"], ["Bob", "Doe"]]
      end

      it "allows extracting specific fields by following associations" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        Post.create!(author: user_1, title: "Post 1", published: true)
        Post.create!(author: user_1, title: "Post 2", published: true)
        Post.create!(author: user_2, title: "Post 3", published: true)
        Post.create!(author: user_1, title: "Post 4", published: false)
        Post.create!(author: user_3, title: "Post 5", published: false)

        Post.pluck([:title, :author__first_name]).to_set.should eq(
          [["Post 1", "John"], ["Post 2", "John"], ["Post 3", "John"], ["Post 4", "John"], ["Post 5", "Bob"]].to_set
        )
      end
    end
  end

  describe "::prefetch" do
    it "allows to prefetch a single one-to-one relation" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      user_profile_1 = TestUserProfile.create!(user: user_1, bio: "Test 1")
      user_profile_2 = TestUserProfile.create!(user: user_2, bio: "Test 2")

      qset = TestUserProfile.prefetch(:user).order(:bio)

      qset.to_a.should eq [user_profile_1, user_profile_2]
      qset[0].get_related_object_variable(:user).should eq user_1
      qset[1].get_related_object_variable(:user).should eq user_2
    end

    it "allows to prefetch a single many-to-one relation" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")

      qset = Post.prefetch(:author).order(:title)

      qset.to_a.should eq [post_1, post_2]
      qset[0].get_related_object_variable(:author).should eq user_1
      qset[1].get_related_object_variable(:author).should eq user_2
    end

    it "allows to prefetch a single many-to-many relation" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)
      Tag.create!(name: "debugging", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      user_1.tags.add(tag_1, tag_3)
      user_2.tags.add(tag_2, tag_3)
      user_3.tags.add(tag_4, tag_5)

      qset = TestUser.prefetch(:tags).order(:username)

      qset.to_a.should eq [user_1, user_2, user_3]
      qset[0].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_1, tag_3]
      qset[1].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_2, tag_3]
      qset[2].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_4, tag_5]
    end

    it "allows to prefetch a single reverse one-to-one relation" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      user_profile_1 = TestUserProfile.create!(user: user_1, bio: "Test 1")
      user_profile_2 = TestUserProfile.create!(user: user_2, bio: "Test 2")

      qset = TestUser.prefetch(:profile).order(:username)

      qset.to_a.should eq [user_1, user_2]
      qset[0].get_reverse_related_object_variable(:profile).should eq user_profile_1
      qset[1].get_reverse_related_object_variable(:profile).should eq user_profile_2
    end

    it "allows to prefetch a single reverse many-to-one relation" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")
      post_4 = Post.create!(author: user_2, title: "Post 4")

      qset = TestUser.prefetch(:posts).order(:username)

      qset.to_a.should eq [user_1, user_2]
      qset[0].posts.result_cache.try(&.sort_by(&.pk!)).should eq [post_1, post_3]
      qset[1].posts.result_cache.try(&.sort_by(&.pk!)).should eq [post_2, post_4]
    end

    it "allows to prefetch a single reverse many-to-many relation" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)
      tag_6 = Tag.create!(name: "debugging", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      user_1.tags.add(tag_1, tag_2, tag_3)
      user_2.tags.add(tag_2, tag_3)
      user_3.tags.add(tag_3, tag_4, tag_5)

      qset = Tag.prefetch(:test_users).order(:pk)

      qset.to_a.should eq [tag_1, tag_2, tag_3, tag_4, tag_5, tag_6]
      qset[0].test_users.result_cache.try(&.sort_by(&.pk!)).should eq [user_1]
      qset[1].test_users.result_cache.try(&.sort_by(&.pk!)).should eq [user_1, user_2]
      qset[2].test_users.result_cache.try(&.sort_by(&.pk!)).should eq [user_1, user_2, user_3]
      qset[3].test_users.result_cache.try(&.sort_by(&.pk!)).should eq [user_3]
      qset[4].test_users.result_cache.try(&.sort_by(&.pk!)).should eq [user_3]
      qset[5].test_users.result_cache.try(&.empty?).should be_true
    end

    it "can prefetch many relations" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)
      Tag.create!(name: "debugging", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      user_1.tags.add(tag_1, tag_3)
      user_2.tags.add(tag_2, tag_3)
      user_3.tags.add(tag_4, tag_5)

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")
      post_4 = Post.create!(author: user_2, title: "Post 4")

      qset = TestUser.prefetch(:tags, :posts).order(:username)

      qset.to_a.should eq [user_1, user_2, user_3]

      qset[0].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_1, tag_3]
      qset[1].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_2, tag_3]
      qset[2].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_4, tag_5]

      qset[0].posts.result_cache.try(&.sort_by(&.pk!)).should eq [post_1, post_3]
      qset[1].posts.result_cache.try(&.sort_by(&.pk!)).should eq [post_2, post_4]
      qset[2].posts.result_cache.try(&.empty?).should be_true
    end

    it "works with relations expressed as strings" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      user_profile_1 = TestUserProfile.create!(user: user_1, bio: "Test 1")
      user_profile_2 = TestUserProfile.create!(user: user_2, bio: "Test 2")

      qset = TestUserProfile.prefetch("user").order(:bio)

      qset.to_a.should eq [user_profile_1, user_profile_2]
      qset[0].get_related_object_variable(:user).should eq user_1
      qset[1].get_related_object_variable(:user).should eq user_2
    end

    it "allows to prefetch a single one-to-one relation with a custom query" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      user_profile_1 = TestUserProfile.create!(user: user_1, bio: "Test 1")
      user_profile_2 = TestUserProfile.create!(user: user_2, bio: "Test 2")

      qset = TestUserProfile.prefetch(:user, TestUser.filter(username: "jd1")).order(:bio)

      qset.to_a.should eq [user_profile_1, user_profile_2]
      qset[0].get_related_object_variable(:user).should eq user_1
      qset[1].get_related_object_variable(:user).should be_nil
    end

    it "allows to prefetch a single many-to-one relation with a custom query" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")

      qset = Post.prefetch(:author, TestUser.filter(username: "jd1")).order(:title)

      qset.to_a.should eq [post_1, post_2]
      qset[0].get_related_object_variable(:author).should eq user_1
      qset[1].get_related_object_variable(:author).should be_nil
    end

    it "allows to prefetch a single many-to-many relation with a custom query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)
      Tag.create!(name: "debugging", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      user_1.tags.add(tag_1, tag_3)
      user_2.tags.add(tag_2, tag_3)
      user_3.tags.add(tag_4, tag_5)

      qset = TestUser.prefetch(:tags, Tag.order(:pk)).order(:username)

      qset.to_a.should eq [user_1, user_2, user_3]
      qset[0].tags.result_cache.should eq [tag_1, tag_3]
      qset[1].tags.result_cache.should eq [tag_2, tag_3]
      qset[2].tags.result_cache.should eq [tag_4, tag_5]
    end

    it "allows to prefetch a single reverse one-to-one relation with a custom query" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      user_profile_1 = TestUserProfile.create!(user: user_1, bio: "Test 1")
      TestUserProfile.create!(user: user_2, bio: "Test 2")

      qset = TestUser.prefetch(:profile, TestUserProfile.filter(bio: "Test 1")).order(:username)

      qset.to_a.should eq [user_1, user_2]
      qset[0].get_reverse_related_object_variable(:profile).should eq user_profile_1
      qset[1].get_reverse_related_object_variable(:profile).should be_nil
    end

    it "allows to prefetch a single reverse many-to-one relation with a custom query" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")
      post_4 = Post.create!(author: user_2, title: "Post 4")

      qset = TestUser.prefetch(:posts, Post.order("-pk")).order(:username)

      qset.to_a.should eq [user_1, user_2]
      qset[0].posts.result_cache.should eq [post_3, post_1]
      qset[1].posts.result_cache.should eq [post_4, post_2]
    end

    it "allows to prefetch a single reverse many-to-many relation with a custom query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)
      tag_6 = Tag.create!(name: "debugging", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "Jane", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      user_1.tags.add(tag_1, tag_2, tag_3)
      user_2.tags.add(tag_2, tag_3)
      user_3.tags.add(tag_3, tag_4, tag_5)

      qset = Tag.prefetch(:test_users, TestUser.filter(first_name: "John")).order(:pk)

      qset.to_a.should eq [tag_1, tag_2, tag_3, tag_4, tag_5, tag_6]
      qset[0].test_users.result_cache.should eq [user_1]
      qset[1].test_users.result_cache.should eq [user_1]
      qset[2].test_users.result_cache.should eq [user_1, user_3]
      qset[3].test_users.result_cache.should eq [user_3]
      qset[4].test_users.result_cache.should eq [user_3]
      qset[5].test_users.result_cache.try(&.empty?).should be_true

      # Other way round
      qset = TestUser.prefetch(:tags, Tag.filter(name: "crystal")).order(:pk)
      qset.to_a.should eq [user_1, user_2, user_3]
      qset[0].tags.result_cache.should eq [tag_2]
      qset[1].tags.result_cache.should eq [tag_2]
      qset[2].tags.result_cache.not_nil!.empty?.should be_true
    end

    it "can prefetch many relations with a custom query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)
      Tag.create!(name: "debugging", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      user_1.tags.add(tag_1, tag_3)
      user_2.tags.add(tag_2, tag_3)
      user_3.tags.add(tag_4, tag_5)

      post_1 = Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      Post.create!(author: user_1, title: "Post 3")
      Post.create!(author: user_2, title: "Post 4")

      qset = TestUser
        .prefetch(:tags, Tag.filter(name: "crystal"))
        .prefetch(:posts, Post.filter(title: "Post 1"))
        .order(:username)

      qset.to_a.should eq [user_1, user_2, user_3]

      qset[0].tags.result_cache.try(&.sort_by(&.pk!)).try(&.empty?).should be_true
      qset[1].tags.result_cache.try(&.sort_by(&.pk!)).should eq [tag_2]
      qset[2].tags.result_cache.try(&.sort_by(&.pk!)).try(&.empty?).should be_true

      qset[0].posts.result_cache.try(&.sort_by(&.pk!)).should eq [post_1]
      qset[1].posts.result_cache.try(&.empty?).should be_true
      qset[2].posts.result_cache.try(&.empty?).should be_true
    end
  end

  describe "::raw" do
    it "returns the expected records for non-parameterized queries" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Tag.raw("select * from app_tag order by id;").to_a.should eq [tag_1, tag_2, tag_3]
      Tag.raw("select * from app_tag where name = 'crystal';").to_a.should eq [tag_2]
    end

    it "returns the expected records for queries involving positional parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Tag.raw("select * from app_tag where name = ?;", ["crystal"]).to_a.should eq [tag_2]
      Tag.raw("select * from app_tag where name = ? or name = ? order by id;", ["ruby", "coding"]).to_a.should eq(
        [tag_1, tag_3]
      )
    end

    it "returns the expected records for queries involving splat positional parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Tag.raw("select * from app_tag where name = ?;", "crystal").to_a.should eq [tag_2]
      Tag.raw("select * from app_tag where name = ? or name = ? order by id;", "ruby", "coding").to_a.should eq(
        [tag_1, tag_3]
      )
    end

    it "returns the expected records for queries involving named parameters expressed as a named tuple" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Tag.raw("select * from app_tag where name = :name;", {name: "crystal"}).to_a.should eq [tag_2]
      Tag.raw(
        "select * from app_tag where name = :name1 or name = :name2 order by id;",
        {name1: "ruby", name2: "coding"}
      ).to_a.should eq(
        [tag_1, tag_3]
      )
    end

    it "returns the expected records for queries involving named parameters expressed as a hash" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Tag.raw("select * from app_tag where name = :name;", {"name" => "crystal"}).to_a.should eq [tag_2]
      Tag.raw(
        "select * from app_tag where name = :name1 or name = :name2 order by id;",
        {"name1" => "ruby", "name2" => "coding"}
      ).to_a.should eq([tag_1, tag_3])
    end

    it "returns the expected records for queries involving double splat named parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Tag.raw("select * from app_tag where name = :name;", name: "crystal").to_a.should eq [tag_2]
      Tag.raw(
        "select * from app_tag where name = :name1 or name = :name2 order by id;",
        name1: "ruby",
        name2: "coding"
      ).to_a.should eq([tag_1, tag_3])
    end
  end

  describe "::scope" do
    with_installed_apps Marten::DB::Model::QueryingSpec::App

    it "allows to define a scope for a model" do
      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::Post.all.to_a.should eq [post_1, post_2, post_3]
      Marten::DB::Model::QueryingSpec::Post.published.to_a.should eq [post_1, post_3]
    end

    it "allows to define a scope that requires arguments for a model" do
      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Top Post 1",
        content: "Content 1",
      )
      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Top Post 2",
        content: "Content 3",
      )

      Marten::DB::Model::QueryingSpec::Post.all.to_a.should eq [post_1, post_2, post_3]
      Marten::DB::Model::QueryingSpec::Post.prefixed("Top").to_a.should eq [post_1, post_3]
    end

    it "defines scopes on a model query set" do
      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::Post.all.to_a.should eq [post_1, post_2, post_3]
      Marten::DB::Model::QueryingSpec::Post.all.published.to_a.should eq [post_1, post_3]
    end

    it "defines scopes that require arguments on a model query set" do
      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Top Post 1",
        content: "Content 1",
      )
      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Top Post 2",
        content: "Content 3",
      )

      Marten::DB::Model::QueryingSpec::Post.all.to_a.should eq [post_1, post_2, post_3]
      Marten::DB::Model::QueryingSpec::Post.all.prefixed("Top").to_a.should eq [post_1, post_3]
    end

    it "defines custom scopes on related sets" do
      author_1 = Marten::DB::Model::QueryingSpec::Author.create!(name: "Author 1", is_admin: true)
      author_2 = Marten::DB::Model::QueryingSpec::Author.create!(name: "Author 2", is_admin: false)

      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 1",
        content: "Content 1",
        author: author_1,
        published: true
      )
      Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
        author: author_2,
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 3",
        content: "Content 3",
        author: author_1,
        published: false
      )

      author_1.posts.to_a.should eq [post_1, post_3]
      author_1.posts.published.to_a.should eq [post_1]
    end

    it "defines custom scopes on many-to-many sets" do
      tag_1 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 1", is_active: true)
      tag_2 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 2", is_active: false)
      tag_3 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 3", is_active: true)
      tag_4 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 4", is_active: true)

      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      post_1.tags.add(tag_1, tag_2, tag_3)

      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_2.tags.add(tag_2, tag_3, tag_4)

      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )
      post_3.tags.add(tag_1, tag_3, tag_4)

      post_1.tags.to_a.should eq [tag_1, tag_2, tag_3]
      post_1.tags.active.to_a.should eq [tag_1, tag_3]
    end

    it "configures scopes that can be chained" do
      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 1",
        content: "Content 1",
        published: true,
        published_at: 2.years.ago,
      )
      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 3",
        content: "Content 3",
        published: true,
        published_at: 1.day.ago,
      )
      post_4 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 4",
        content: "Content 4",
        published: true,
        published_at: 1.week.ago,
      )

      Marten::DB::Model::QueryingSpec::Post.all.to_a.should eq [post_1, post_2, post_3, post_4]
      Marten::DB::Model::QueryingSpec::Post.published.recent.to_a.should eq [post_3, post_4]
    end

    it "allows to define a scope for a model through the use of an abstract parent model" do
      post_1 = Marten::DB::Model::QueryingSpec::NonAbstractPost.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      post_2 = Marten::DB::Model::QueryingSpec::NonAbstractPost.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::NonAbstractPost.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::NonAbstractPost.all.to_a.should eq [post_1, post_2, post_3]
      Marten::DB::Model::QueryingSpec::NonAbstractPost.published.to_a.should eq [post_1, post_3]
    end

    it "allows to define a scope for a model through the use of a non-abstract parent model" do
      post_1 = Marten::DB::Model::QueryingSpec::ChildPost.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      post_2 = Marten::DB::Model::QueryingSpec::ChildPost.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::ChildPost.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::ChildPost.all.to_a.should eq [post_1, post_2, post_3]
      Marten::DB::Model::QueryingSpec::ChildPost.published.to_a.should eq [post_1, post_3]
    end

    it "ensures scopes with similar names are independent of each other across different models" do
      tag_1 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 1", is_active: true)
      tag_2 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 2", is_active: true)
      tag_3 = Marten::DB::Model::QueryingSpec::Tag.create!(name: "Tag 3", is_active: true)

      post_1 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 1",
        content: "Content 1",
        published: true,
        published_at: 2.days.ago,
      )
      post_2 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 2",
        content: "Content 2",
        published: true,
        published_at: 3.months.ago,
      )
      post_3 = Marten::DB::Model::QueryingSpec::Post.create!(
        title: "Post 3",
        content: "Content 3",
        published: true,
        published_at: 1.month.ago,
      )

      Marten::DB::Model::QueryingSpec::Post.recent.to_set.should eq [post_1, post_2, post_3].to_set
      Marten::DB::Model::QueryingSpec::Tag.recent.to_set.should eq [tag_1, tag_2, tag_3].to_set
    end
  end

  describe "::sum" do
    it "properly calculates the sum" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post 1", score: 5.0)
      Post.create!(author: user, title: "Example post 2", score: 5.0)

      Post.sum(:score).should eq 10.00
    end
  end

  describe "::unscoped" do
    with_installed_apps Marten::DB::Model::QueryingSpec::App

    it "ignores the default scope" do
      post_1 = Marten::DB::Model::QueryingSpec::PostWithDefaultScope.create!(
        title: "Post 1",
        content: "Content 1",
        published: true
      )
      post_2 = Marten::DB::Model::QueryingSpec::PostWithDefaultScope.create!(
        title: "Post 2",
        content: "Content 2",
        published: false
      )
      post_3 = Marten::DB::Model::QueryingSpec::PostWithDefaultScope.create!(
        title: "Post 3",
        content: "Content 3",
        published: true
      )

      Marten::DB::Model::QueryingSpec::PostWithDefaultScope.all.to_a.should eq [post_1, post_3]
      Marten::DB::Model::QueryingSpec::PostWithDefaultScope.unscoped.to_a.should eq [post_1, post_2, post_3]
    end
  end

  describe "::update" do
    it "allows to update all the records with values specified as keyword arguments" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      TestUser.update(last_name: "Updated", is_admin: true).should eq 3

      user_1.reload
      user_1.first_name.should eq "John"
      user_1.last_name.should eq "Updated"
      user_1.is_admin.should be_true

      user_2.reload
      user_2.first_name.should eq "John"
      user_2.last_name.should eq "Updated"
      user_2.is_admin.should be_true

      user_3.reload
      user_3.first_name.should eq "Bob"
      user_3.last_name.should eq "Updated"
      user_3.is_admin.should be_true
    end

    it "allows to update all the records with values specified as a hash" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      TestUser.update({"last_name" => "Updated", "is_admin" => true}).should eq 3

      user_1.reload
      user_1.first_name.should eq "John"
      user_1.last_name.should eq "Updated"
      user_1.is_admin.should be_true

      user_2.reload
      user_2.first_name.should eq "John"
      user_2.last_name.should eq "Updated"
      user_2.is_admin.should be_true

      user_3.reload
      user_3.first_name.should eq "Bob"
      user_3.last_name.should eq "Updated"
      user_3.is_admin.should be_true
    end

    it "allows to update all the records with values specified as a named tuple" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      TestUser.update({last_name: "Updated", is_admin: true}).should eq 3

      user_1.reload
      user_1.first_name.should eq "John"
      user_1.last_name.should eq "Updated"
      user_1.is_admin.should be_true

      user_2.reload
      user_2.first_name.should eq "John"
      user_2.last_name.should eq "Updated"
      user_2.is_admin.should be_true

      user_3.reload
      user_3.first_name.should eq "Bob"
      user_3.last_name.should eq "Updated"
      user_3.is_admin.should be_true
    end
  end

  describe "::update_or_create" do
    with_installed_apps Marten::DB::Model::QueryingSpec::App

    it "updates the record matched by the specified arguments" do
      tag = Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)

      updated_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create(
        updates: {is_active: false},
        defaults: {name: "crystal", is_active: true},
        name: "crystal"
      )

      updated_tag.should eq tag

      tag.reload
      tag.is_active.should be_false
    end

    it "creates a record using the specified updates if no record is found" do
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)

      new_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create(
        updates: {name: "newtag", is_active: true},
        name: "newtag"
      )
      new_tag.persisted?.should be_true
      new_tag.name.should eq "newtag"
      new_tag.is_active.should be_true

      Marten::DB::Model::QueryingSpec::Tag.all.size.should eq 2
    end

    it "uses defaults when creating a new record if they are provided" do
      new_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create(
        updates: {name: "unused", is_active: true},
        defaults: {name: "newtag", is_active: false},
        name: "newtag"
      )

      new_tag.persisted?.should be_true
      new_tag.is_active.should be_false
      new_tag.name.should eq "newtag"
    end

    it "does not use lookup filters when creating a new record" do
      new_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create(
        updates: {name: "filtered"},
        is_active: false
      )

      new_tag.persisted?.should be_true
      new_tag.name.should eq "filtered"
      new_tag.is_active.should be_true
    end

    it "raises MultipleRecordsFound if the filters match multiple records" do
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: false)

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        Marten::DB::Model::QueryingSpec::Tag.update_or_create(
          updates: {is_active: true},
          name: "crystal"
        )
      end
    end
  end

  describe "::update_or_create!" do
    with_installed_apps Marten::DB::Model::QueryingSpec::App

    it "updates the record matched by the specified arguments" do
      tag = Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)

      updated_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
        updates: {is_active: false},
        defaults: {name: "crystal", is_active: true},
        name: "crystal"
      )

      updated_tag.should eq tag

      tag.reload
      tag.is_active.should be_false
    end

    it "creates a record using the specified updates if no record is found" do
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)

      new_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
        updates: {name: "newtag", is_active: true},
        name: "newtag"
      )
      new_tag.persisted?.should be_true
      new_tag.name.should eq "newtag"
      new_tag.is_active.should be_true

      Marten::DB::Model::QueryingSpec::Tag.all.size.should eq 2
    end

    it "uses defaults when creating a new record if they are provided" do
      new_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
        updates: {name: "unused", is_active: true},
        defaults: {name: "newtag", is_active: false},
        name: "newtag"
      )

      new_tag.persisted?.should be_true
      new_tag.is_active.should be_false
      new_tag.name.should eq "newtag"
    end

    it "does not use lookup filters when creating a new record" do
      new_tag = Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
        updates: {name: "filtered"},
        is_active: false
      )

      new_tag.persisted?.should be_true
      new_tag.name.should eq "filtered"
      new_tag.is_active.should be_true
    end

    it "raises MultipleRecordsFound if the filters match multiple records" do
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: false)

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
          updates: {is_active: true},
          name: "crystal"
        )
      end
    end

    it "raises InvalidRecord if the updated record is invalid" do
      Marten::DB::Model::QueryingSpec::Tag.create!(name: "crystal", is_active: true)

      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
          updates: {name: ""},
          name: "crystal"
        )
      end
    end

    it "raises InvalidRecord if the created record is invalid" do
      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Marten::DB::Model::QueryingSpec::Tag.update_or_create!(
          updates: {name: ""},
          name: "invalid"
        )
      end
    end
  end

  describe "::using" do
    before_each do
      TestUser.using(:other).create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.using(:other).create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "ruby", is_active: true)
      Tag.using(:other).create!(name: "coding", is_active: true)
      Tag.using(:other).create!(name: "crystal", is_active: false)
    end

    it "returns a default queryset using the specified database when the connection is expressed as a symbol" do
      qs1 = TestUser.using(:other)
      results1 = qs1.to_a
      results1.size.should eq 2
      results1.includes?(TestUser.using(:other).get!(username: "jd1")).should be_true
      results1.includes?(TestUser.using(:other).get!(username: "jd1")).should be_true

      qs2 = Tag.using(:other)
      results2 = qs2.to_a
      results2.size.should eq 1
      results2.includes?(Tag.using(:other).get(name: "coding")).should be_true
    end

    it "returns a default queryset using the specified database when the connection is expressed as a string" do
      qs1 = TestUser.using(:other)
      results1 = qs1.to_a
      results1.size.should eq 2
      results1.includes?(TestUser.using("other").get!(username: "jd1")).should be_true
      results1.includes?(TestUser.using("other").get!(username: "jd1")).should be_true

      qs2 = Tag.using("other")
      results2 = qs2.to_a
      results2.size.should eq 1
      results2.includes?(Tag.using("other").get(name: "coding")).should be_true
    end

    it "does not have any effect when called with a nil value" do
      qs = TestUser.using(nil)
      results = qs.to_a
      results.size.should eq 1
      results.includes?(TestUser.get!(username: "foo")).should be_true
    end
  end
end
