require "./spec_helper"
require "./prefetcher_spec/app"

describe Marten::DB::Query::Prefetcher do
  with_installed_apps Marten::DB::Query::PrefetcherSpec::App

  describe "#execute" do
    it "allows to prefetch a single one-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      records = Marten::DB::Query::PrefetcherSpec::Pseudonym.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
    end

    it "always uses unscoped queries when prefetching one-to-one relations" do
      author_1 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Pqr Doe")

      Marten::DB::Query::PrefetcherSpec::Profile.create!(scoped_author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(scoped_author: author_2, name: "Def")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(scoped_author: author_3, name: "Ghi")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(scoped_author: author_4, name: "Jkl")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(scoped_author: author_5, name: "Mno")

      records = Marten::DB::Query::PrefetcherSpec::Profile.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["scoped_author"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_related_object_variable(:scoped_author).should eq author_1
      records[1].get_related_object_variable(:scoped_author).should eq author_2
      records[2].get_related_object_variable(:scoped_author).should eq author_3
      records[3].get_related_object_variable(:scoped_author).should eq author_4
      records[4].get_related_object_variable(:scoped_author).should eq author_5
    end

    it "allows to prefetch a single many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
    end

    it "always uses unscoped queries when prefetching many-to-one relations" do
      author_1 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Pqr Doe")

      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", scoped_author: author_1)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", scoped_author: author_2)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", scoped_author: author_3)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Jkl", scoped_author: author_4)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Mno", scoped_author: author_5)

      records = Marten::DB::Query::PrefetcherSpec::Conference.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["scoped_author"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_related_object_variable(:scoped_author).should eq author_1
      records[1].get_related_object_variable(:scoped_author).should eq author_2
      records[2].get_related_object_variable(:scoped_author).should eq author_3
      records[3].get_related_object_variable(:scoped_author).should eq author_4
      records[4].get_related_object_variable(:scoped_author).should eq author_5
    end

    it "allows to prefetch a single many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_4, author_5)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_4, author_5]
    end

    it "always uses unscoped queries when prefetching many-to-many relations" do
      author_1 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::ScopedAuthor.create!(name: "Pqr Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.scoped_authors.add(author_1, author_3)
      book_2.scoped_authors.add(author_2, author_3)
      book_3.scoped_authors.add(author_4, author_5)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["scoped_authors"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].scoped_authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].scoped_authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]
      records[2].scoped_authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_4, author_5]
    end

    it "allows to prefetch a single reverse one-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      pseudonym_2 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["pseudonym"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
      records[1].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_2
    end

    it "allows to prefetch a single reverse many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", publisher: publisher_1)
      author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe", publisher: publisher_2)

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_4]
    end

    it "allows to prefetch a single reverse many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_4, author_5)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["books"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1]
      records[1].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2]
      records[2].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
      records[3].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
      records[4].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
      records[5].books.result_cache.try(&.empty?).should be_true
    end

    it "can prefetch many relations" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_4, author_5)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher", "books"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
      records[2].get_related_object_variable(:publisher).should be_nil
      records[3].get_related_object_variable(:publisher).should be_nil
      records[4].get_related_object_variable(:publisher).should be_nil
      records[5].get_related_object_variable(:publisher).should be_nil

      records[0].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1]
      records[1].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2]
      records[2].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
      records[3].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
      records[4].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
      records[5].books.result_cache.try(&.empty?).should be_true
    end

    it "can prefetch many relations that involve some redundancy" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", publisher: publisher_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", publisher: publisher_2)

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")
      author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")
      author_5 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Mno Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_4, author_5)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher", "books", "publisher__conferences"],
        using: nil
      )

      expect_db_query_count(4) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
      records[2].get_related_object_variable(:publisher).should be_nil
      records[3].get_related_object_variable(:publisher).should be_nil
      records[4].get_related_object_variable(:publisher).should be_nil
      records[5].get_related_object_variable(:publisher).should be_nil

      records[0].publisher!.conferences.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [conference_1]
      records[1].publisher!.conferences.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [conference_2]

      records[0].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1]
      records[1].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2]
      records[2].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
      records[3].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
      records[4].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
      records[5].books.result_cache.try(&.empty?).should be_true
    end

    it "completes when prefetching a single one-to-one relation that is not available on some records" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["bio"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_related_object_variable(:bio).should eq bio_1
      records[1].get_related_object_variable(:bio).should eq bio_2
      records[2].get_related_object_variable(:bio).should be_nil
      records[3].get_related_object_variable(:bio).should be_nil
    end

    it "completes when prefetching a single many-to-one relation that is not available on some records" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
      records[2].get_related_object_variable(:publisher).should be_nil
      records[3].get_related_object_variable(:publisher).should be_nil
    end

    it "completes when prefetching a single reverse one-to-one relation that is not available on some records" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["pseudonym"],
        using: nil
      )

      expect_db_query_count(1) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
      records[1].get_reverse_related_object_variable(:pseudonym).should be_nil
    end

    it "allows to prefetch a one-to-one relation followed by another one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)

      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      records = Marten::DB::Query::PrefetcherSpec::Pseudonym.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__bio"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[0].author!.get_related_object_variable(:bio).should eq bio_1
      records[1].author!.get_related_object_variable(:bio).should eq bio_2
    end

    it "allows to prefetch a one-to-one relation followed by a many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      records = Marten::DB::Query::PrefetcherSpec::Pseudonym.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__publisher"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[0].author!.get_related_object_variable(:publisher).should eq publisher_1
      records[1].author!.get_related_object_variable(:publisher).should be_nil
    end

    it "allows to prefetch a one-to-one relation followed by a many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")
      Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Jkl")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)

      records = Marten::DB::Query::PrefetcherSpec::Pseudonym.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__book_genres"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[0].author!.book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_1, book_genre_3]
      records[1].author!.book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_2, book_genre_3]
    end

    it "allows to prefetch a one-to-one relation followed by a reverse one-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      pseudonym_2 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_2, name: "Def")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_3, name: "Ghi")

      records = Marten::DB::Query::PrefetcherSpec::Profile.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__pseudonym"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[2].get_related_object_variable(:author).should eq author_3
      records[0].author!.get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
      records[1].author!.get_reverse_related_object_variable(:pseudonym).should eq pseudonym_2
      records[2].author!.get_reverse_related_object_variable(:pseudonym).should be_nil
    end

    it "allows to prefetch a one-to-one relation followed by a reverse many-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)
      conference_3 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", author: author_3)
      conference_4 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Jkl", author: author_1)
      conference_5 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Mno", author: author_2)

      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_2, name: "Def")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_3, name: "Ghi")

      records = Marten::DB::Query::PrefetcherSpec::Profile.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__conferences"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[2].get_related_object_variable(:author).should eq author_3
      records[0].author!.conferences.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [conference_1, conference_4]
      records[1].author!.conferences.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [conference_2, conference_5]
      records[2].author!.conferences.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [conference_3]
    end

    it "allows to prefetch a one-to-one relation followed by a reverse many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_1, author_2)

      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_1, name: "Abc")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_2, name: "Def")
      Marten::DB::Query::PrefetcherSpec::Profile.create!(author: author_3, name: "Ghi")

      records = Marten::DB::Query::PrefetcherSpec::Profile.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__books"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[2].get_related_object_variable(:author).should eq author_3
      records[0].author!.books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_3]
      records[1].author!.books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2, book_3]
      records[2].author!.books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
    end

    it "allows to prefetch a many-to-one relation followed by another many-to-one relation" do
      country_1 = Marten::DB::Query::PrefetcherSpec::Country.create!(name: "Abc")
      country_2 = Marten::DB::Query::PrefetcherSpec::Country.create!(name: "Def")

      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc", country: country_1)
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def", country: country_2)

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher__country"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
      records[0].publisher!.get_related_object_variable(:country).should eq country_1
      records[1].publisher!.get_related_object_variable(:country).should eq country_2
    end

    it "allows to prefetch a many-to-one relation followed by a one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)

      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::Conference.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__bio"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[0].author!.get_related_object_variable(:bio).should eq bio_1
      records[1].author!.get_related_object_variable(:bio).should eq bio_2
    end

    it "allows to prefetch a many-to-one relation followed by a many-to-many relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")
      Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Jkl")

      publisher_1.book_genres.add(book_genre_1, book_genre_3)
      publisher_2.book_genres.add(book_genre_2, book_genre_3)

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher__book_genres"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
      records[0].publisher!.book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_1, book_genre_3]
      records[1].publisher!.book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_2, book_genre_3]
    end

    it "allows to prefetch a many-to-one relation followed by a reverse one-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      pseudonym_2 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::Conference.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__pseudonym"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[0].author!.get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
      records[1].author!.get_reverse_related_object_variable(:pseudonym).should eq pseudonym_2
    end

    it "allows to prefetch a many-to-one relation followed by a reverse many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", publisher: publisher_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", publisher: publisher_2)
      conference_3 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", publisher: publisher_1)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["publisher__conferences"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_related_object_variable(:publisher).should eq publisher_1
      records[1].get_related_object_variable(:publisher).should eq publisher_2
      records[0].publisher!.get_reverse_related_queryset(:conferences).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_1, conference_3]
      records[1].publisher!.get_reverse_related_queryset(:conferences).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_2]
    end

    it "allows to prefetch a many-to-one relation followed by a reverse many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_2)
      book_2.authors.add(author_2)
      book_3.authors.add(author_1)

      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::Conference.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__books"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_related_object_variable(:author).should eq author_1
      records[1].get_related_object_variable(:author).should eq author_2
      records[0].author!.get_reverse_related_queryset(:books).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_3]
      records[1].author!.get_reverse_related_queryset(:books).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_2]
    end

    it "allows to prefetch a many-to-many relation followed by a one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__bio"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]

      records[0].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_1
      records[0].authors.result_cache.not_nil![1].get_related_object_variable(:bio).should eq bio_3

      records[1].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_2
      records[1].authors.result_cache.not_nil![1].get_related_object_variable(:bio).should eq bio_3
    end

    it "allows to prefetch a many-to-many relation followed by a many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__publisher"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]

      records[0].authors.result_cache.not_nil![0].get_related_object_variable(:publisher).should eq publisher_1
      records[0].authors.result_cache.not_nil![1].get_related_object_variable(:publisher).should be_nil

      records[1].authors.result_cache.not_nil![0].get_related_object_variable(:publisher).should eq publisher_2
      records[1].authors.result_cache.not_nil![1].get_related_object_variable(:publisher).should be_nil
    end

    it "allows to prefetch a many-to-many relation followed by another many-to-many relation" do
      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__book_genres"],
        using: nil
      )

      expect_db_query_count(4) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]

      records[0].authors.result_cache.not_nil![0].book_genres.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_genre_1, book_genre_3]
      records[0].authors.result_cache.not_nil![1].book_genres.result_cache.not_nil!.should be_empty

      records[1].authors.result_cache.not_nil![0].book_genres.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_genre_2, book_genre_3]
      records[1].authors.result_cache.not_nil![1].book_genres.result_cache.not_nil!.should be_empty
    end

    it "allows to prefetch a many-to-many relation followed by a reverse one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      pseudonym_2 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__pseudonym"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]

      records[0].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
      records[0].authors.result_cache.not_nil![1].get_reverse_related_object_variable(:pseudonym).should be_nil

      records[1].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_2
      records[1].authors.result_cache.not_nil![1].get_reverse_related_object_variable(:pseudonym).should be_nil
    end

    it "allows to prefetch a many-to-many relation followed by a reverse many-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)
      conference_3 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", author: author_3)
      conference_4 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Jkl", author: author_1)
      conference_5 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Mno", author: author_2)

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)

      records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__conferences"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]

      records[0].authors.result_cache.not_nil![0]
        .get_reverse_related_queryset(:conferences)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [conference_1, conference_4]
      records[0].authors.result_cache.not_nil![1]
        .get_reverse_related_queryset(:conferences)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [conference_3]

      records[1].authors.result_cache.not_nil![0]
        .get_reverse_related_queryset(:conferences)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [conference_2, conference_5]
      records[1].authors.result_cache.not_nil![1]
        .get_reverse_related_queryset(:conferences)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [conference_3]
    end

    it "allows to prefetch a many-to-many relation followed by a reverse many-to-many relation" do
      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1, book_genre_2)

      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      publisher_1.book_genres.add(book_genre_1, book_genre_3)
      publisher_2.book_genres.add(book_genre_2, book_genre_3)

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["book_genres__publishers"],
        using: nil
      )

      expect_db_query_count(4) { prefetcher.execute }

      records[0].book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_1, book_genre_3]
      records[1].book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_2, book_genre_3]

      records[0].book_genres.result_cache.not_nil![0]
        .get_reverse_related_queryset(:publishers)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [publisher_1]
      records[0].book_genres.result_cache.not_nil![1]
        .get_reverse_related_queryset(:publishers)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [publisher_1, publisher_2]

      records[1].book_genres.result_cache.not_nil![0]
        .get_reverse_related_queryset(:publishers)
        .result_cache
        .try(&.sort_by(&.pk!.to_s)).should eq [publisher_2]
      records[1].book_genres.result_cache.not_nil![1]
        .get_reverse_related_queryset(:publishers)
        .result_cache
        .try(&.sort_by(&.pk!.to_s))
        .should eq [publisher_1, publisher_2]
    end

    it "allows to prefetch a reverse one-to-one relation followed by a one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      signature_1 = Marten::DB::Query::PrefetcherSpec::Signature.create!(content: "Abc")
      signature_2 = Marten::DB::Query::PrefetcherSpec::Signature.create!(content: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1, signature: signature_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2, signature: signature_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      records = Marten::DB::Query::PrefetcherSpec::Bio.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__signature"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:author).should eq author_1
      records[1].get_reverse_related_object_variable(:author).should eq author_2
      records[2].get_reverse_related_object_variable(:author).should eq author_3
      records[0].author!.get_related_object_variable(:signature).should eq signature_1
      records[1].author!.get_related_object_variable(:signature).should eq signature_2
      records[2].author!.get_related_object_variable(:signature).should be_nil
    end

    it "allows to prefetch a reverse one-to-one relation followed by a many-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1, publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2, publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      records = Marten::DB::Query::PrefetcherSpec::Bio.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__publisher"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:author).should eq author_1
      records[1].get_reverse_related_object_variable(:author).should eq author_2
      records[2].get_reverse_related_object_variable(:author).should eq author_3
      records[0].author!.get_related_object_variable(:publisher).should eq publisher_1
      records[1].author!.get_related_object_variable(:publisher).should eq publisher_2
      records[2].author!.get_related_object_variable(:publisher).should be_nil
    end

    it "allows to prefetch a reverse one-to-one relation followed by a many-to-many relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)

      records = Marten::DB::Query::PrefetcherSpec::Bio.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__book_genres"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:author).should eq author_1
      records[1].get_reverse_related_object_variable(:author).should eq author_2
      records[2].get_reverse_related_object_variable(:author).should eq author_3
      records[0].author!.book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_1, book_genre_3]
      records[1].author!.book_genres.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_genre_2, book_genre_3]
      records[2].author!.book_genres.result_cache.not_nil!.should be_empty
    end

    it "allows to prefetch a reverse one-to-one relation followed by another reverse one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_1, name: "Abc")
      pseudonym_2 = Marten::DB::Query::PrefetcherSpec::Pseudonym.create!(author: author_2, name: "Def")

      records = Marten::DB::Query::PrefetcherSpec::Bio.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__pseudonym"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:author).should eq author_1
      records[1].get_reverse_related_object_variable(:author).should eq author_2
      records[2].get_reverse_related_object_variable(:author).should eq author_3
      records[0].author!.get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
      records[1].author!.get_reverse_related_object_variable(:pseudonym).should eq pseudonym_2
      records[2].author!.get_reverse_related_object_variable(:pseudonym).should be_nil
    end

    it "allows to prefetch a reverse one-to-one relation followed by a reverse many-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)
      conference_3 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", author: author_3)
      conference_4 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Jkl", author: author_1)

      records = Marten::DB::Query::PrefetcherSpec::Bio.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__conferences"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:author).should eq author_1
      records[1].get_reverse_related_object_variable(:author).should eq author_2
      records[2].get_reverse_related_object_variable(:author).should eq author_3
      records[0].author!.get_reverse_related_queryset(:conferences).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_1, conference_4]
      records[1].author!.get_reverse_related_queryset(:conferences).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_2]
      records[2].author!.get_reverse_related_queryset(:conferences).result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_3]
    end

    it "allows to prefetch a reverse one-to-one relation followed by a reverse many-to-many relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_1, author_2)

      records = Marten::DB::Query::PrefetcherSpec::Bio.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["author__books"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].get_reverse_related_object_variable(:author).should eq author_1
      records[1].get_reverse_related_object_variable(:author).should eq author_2
      records[2].get_reverse_related_object_variable(:author).should eq author_3
      records[0].author!.books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_3]
      records[1].author!.books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2, book_3]
      records[2].author!.books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
    end

    it "allows to prefetch a reverse many-to-one relation followed by a one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1, publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2, publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3, publisher: publisher_1)

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__bio"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[0].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_1
      records[0].authors.result_cache.not_nil![1].get_related_object_variable(:bio).should eq bio_3
      records[1].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_2
    end

    it "allows to prefetch a reverse many-to-one relation followed by a many-to-one relation" do
      country_1 = Marten::DB::Query::PrefetcherSpec::Country.create!(name: "Abc")
      country_2 = Marten::DB::Query::PrefetcherSpec::Country.create!(name: "Def")
      country_3 = Marten::DB::Query::PrefetcherSpec::Country.create!(name: "Ghi")

      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(
        name: "Abc Doe",
        country: country_1,
        publisher: publisher_1,
      )
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(
        name: "Def Doe",
        country: country_2,
        publisher: publisher_2,
      )
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(
        name: "Ghi Doe",
        country: country_3,
        publisher: publisher_1,
      )

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__country"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[0].authors.result_cache.not_nil![0].get_related_object_variable(:country).should eq country_1
      records[0].authors.result_cache.not_nil![1].get_related_object_variable(:country).should eq country_3
      records[1].authors.result_cache.not_nil![0].get_related_object_variable(:country).should eq country_2
    end

    it "allows to prefetch a reverse many-to-one relation followed by a many-to-many relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", publisher: publisher_1)

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__book_genres"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[0].authors.result_cache.not_nil![0].book_genres.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_genre_1, book_genre_3]
      records[0].authors.result_cache.not_nil![1].book_genres.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_genre_1]
      records[1].authors.result_cache.not_nil![0].book_genres.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_genre_2, book_genre_3]
    end

    it "allows to prefetch a reverse many-to-one relation followed by a reverse one-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", publisher: publisher_1)

      profile_1 = Marten::DB::Query::PrefetcherSpec::Profile.create!(name: "Abc", author: author_1)
      profile_2 = Marten::DB::Query::PrefetcherSpec::Profile.create!(name: "Def", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__profile"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[0].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:profile).should eq profile_1
      records[0].authors.result_cache.not_nil![1].get_reverse_related_object_variable(:profile).should be_nil
      records[1].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:profile).should eq profile_2
    end

    it "allows to prefetch a reverse many-to-one relation followed by another reverse many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", publisher: publisher_1)

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)
      conference_3 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", author: author_3)
      conference_4 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Jkl", author: author_1)
      conference_5 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Mno", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__conferences"],
        using: nil
      )

      expect_db_query_count(2) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[0].authors.result_cache.not_nil![0].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_1, conference_4]
      records[0].authors.result_cache.not_nil![1].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_3]
      records[1].authors.result_cache.not_nil![0].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_2, conference_5]
    end

    it "allows to prefetch a reverse many-to-one relation followed by a reverse many-to-many relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", publisher: publisher_1)

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_1)

      records = Marten::DB::Query::PrefetcherSpec::Publisher.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__books"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[0].authors.result_cache.not_nil![0].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_3]
      records[0].authors.result_cache.not_nil![1].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_2]
      records[1].authors.result_cache.not_nil![0].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_2]
    end

    it "allows to prefetch a reverse many-to-many relation followed by a one-to-one relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")
      bio_2 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Def")
      bio_3 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Ghi")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", bio: bio_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe", bio: bio_3)

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      records = Marten::DB::Query::PrefetcherSpec::BookGenre.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__bio"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_2]
      records[0].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_1
      records[0].authors.result_cache.not_nil![1].get_related_object_variable(:bio).should eq bio_3
      records[1].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_2
      records[2].authors.result_cache.not_nil![0].get_related_object_variable(:bio).should eq bio_1
      records[2].authors.result_cache.not_nil![1].get_related_object_variable(:bio).should eq bio_2
    end

    it "allows to prefetch a reverse many-to-many relation followed by a many-to-one relation" do
      publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Abc")
      publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.create!(name: "Def")

      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", publisher: publisher_1)
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe", publisher: publisher_2)
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      records = Marten::DB::Query::PrefetcherSpec::BookGenre.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__publisher"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_2]
      records[0].authors.result_cache.not_nil![0].get_related_object_variable(:publisher).should eq publisher_1
      records[0].authors.result_cache.not_nil![1].get_related_object_variable(:publisher).should be_nil
      records[1].authors.result_cache.not_nil![0].get_related_object_variable(:publisher).should eq publisher_2
      records[2].authors.result_cache.not_nil![0].get_related_object_variable(:publisher).should eq publisher_1
      records[2].authors.result_cache.not_nil![1].get_related_object_variable(:publisher).should eq publisher_2
    end

    it "allows to prefetch a reverse many-to-many relation followed by a many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      award_1 = Marten::DB::Query::PrefetcherSpec::Award.create!(name: "Abc")
      award_2 = Marten::DB::Query::PrefetcherSpec::Award.create!(name: "Def")
      award_3 = Marten::DB::Query::PrefetcherSpec::Award.create!(name: "Ghi")

      author_1.awards.add(award_1, award_3)
      author_2.awards.add(award_2, award_3)
      author_3.awards.add(award_1)

      records = Marten::DB::Query::PrefetcherSpec::BookGenre.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__awards"],
        using: nil
      )

      expect_db_query_count(4) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_2]
      records[0].authors.result_cache.not_nil![0].awards.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [award_1, award_3]
      records[0].authors.result_cache.not_nil![1].awards.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [award_1]
      records[1].authors.result_cache.not_nil![0].awards.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [award_2, award_3]
      records[2].authors.result_cache.not_nil![0].awards.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [award_1, award_3]
      records[2].authors.result_cache.not_nil![1].awards.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [award_2, award_3]
    end

    it "allows to prefetch a reverse many-to-many relation followed by a reverse one-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      profile_1 = Marten::DB::Query::PrefetcherSpec::Profile.create!(name: "Abc", author: author_1)
      profile_2 = Marten::DB::Query::PrefetcherSpec::Profile.create!(name: "Def", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::BookGenre.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__profile"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_2]
      records[0].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:profile).should eq profile_1
      records[0].authors.result_cache.not_nil![1].get_reverse_related_object_variable(:profile).should be_nil
      records[1].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:profile).should eq profile_2
      records[2].authors.result_cache.not_nil![0].get_reverse_related_object_variable(:profile).should eq profile_1
      records[2].authors.result_cache.not_nil![1].get_reverse_related_object_variable(:profile).should eq profile_2
    end

    it "allows to prefetch a reverse many-to-many relation followed by a reverse many-to-one relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      conference_1 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Abc", author: author_1)
      conference_2 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Def", author: author_2)
      conference_3 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Ghi", author: author_3)
      conference_4 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Jkl", author: author_1)
      conference_5 = Marten::DB::Query::PrefetcherSpec::Conference.create!(name: "Mno", author: author_2)

      records = Marten::DB::Query::PrefetcherSpec::BookGenre.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__conferences"],
        using: nil
      )

      expect_db_query_count(3) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_2]
      records[0].authors.result_cache.not_nil![0].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_1, conference_4]
      records[0].authors.result_cache.not_nil![1].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_3]
      records[1].authors.result_cache.not_nil![0].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_2, conference_5]
      records[2].authors.result_cache.not_nil![0].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_1, conference_4]
      records[2].authors.result_cache.not_nil![1].conferences.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [conference_2, conference_5]
    end

    it "allows to prefetch a reverse many-to-many relation followed by another reverse many-to-many relation" do
      author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
      author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Doe")

      book_genre_1 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Abc")
      book_genre_2 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Def")
      book_genre_3 = Marten::DB::Query::PrefetcherSpec::BookGenre.create!(name: "Ghi")

      author_1.book_genres.add(book_genre_1, book_genre_3)
      author_2.book_genres.add(book_genre_2, book_genre_3)
      author_3.book_genres.add(book_genre_1)

      book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
      book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
      book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

      book_1.authors.add(author_1, author_3)
      book_2.authors.add(author_2, author_3)
      book_3.authors.add(author_1)

      records = Marten::DB::Query::PrefetcherSpec::BookGenre.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["authors__books"],
        using: nil
      )

      expect_db_query_count(4) { prefetcher.execute }

      records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
      records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_2]
      records[0].authors.result_cache.not_nil![0].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_3]
      records[0].authors.result_cache.not_nil![1].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_2]
      records[1].authors.result_cache.not_nil![0].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_2]
      records[2].authors.result_cache.not_nil![0].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_1, book_3]
      records[2].authors.result_cache.not_nil![1].books.result_cache.try(&.sort_by(&.pk!.to_s))
        .should eq [book_2]
    end

    it "raises if the relation does not exist" do
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["unknown"],
        using: nil
      )

      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Cannot find 'unknown' relation on Marten::DB::Query::PrefetcherSpec::Author record, " \
        "'unknown' is not a relation that can be prefetched",
      ) do
        prefetcher.execute
      end
    end

    it "raises if a relation among other valid relations does not exist" do
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["bio", "unknown"],
        using: nil
      )

      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Cannot find 'unknown' relation on Marten::DB::Query::PrefetcherSpec::Author record, " \
        "'unknown' is not a relation that can be prefetched",
      ) do
        prefetcher.execute
      end
    end

    it "raises if the composite relation contains a part that does not match an exiting relation" do
      bio_1 = Marten::DB::Query::PrefetcherSpec::Bio.create!(content: "Abc")

      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe", bio: bio_1)
      Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")

      records = Marten::DB::Query::PrefetcherSpec::Author.order(:pk).to_a

      prefetcher = Marten::DB::Query::Prefetcher.new(
        records: Array(Marten::DB::Model).new.concat(records),
        relations: ["bio__unknown"],
        using: nil
      )

      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Cannot find 'unknown' relation on Marten::DB::Query::PrefetcherSpec::Bio record, " \
        "'unknown' is not a relation that can be prefetched",
      ) do
        prefetcher.execute
      end
    end

    context "with a non-default database" do
      it "allows to prefetch a single one-to-one relation" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Def Doe")

        Marten::DB::Query::PrefetcherSpec::Pseudonym.using(:other).create!(author: author_1, name: "Abc")
        Marten::DB::Query::PrefetcherSpec::Pseudonym.using(:other).create!(author: author_2, name: "Def")

        records = Marten::DB::Query::PrefetcherSpec::Pseudonym.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["author"],
          using: "other",
        )

        expect_db_query_count(1) { prefetcher.execute }

        records[0].get_related_object_variable(:author).should eq author_1
        records[1].get_related_object_variable(:author).should eq author_2
      end

      it "allows to prefetch a single many-to-one relation" do
        publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).create!(name: "Abc")
        publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).create!(name: "Def")

        Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Abc Doe", publisher: publisher_1)
        Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Def Doe", publisher: publisher_2)

        records = Marten::DB::Query::PrefetcherSpec::Author.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["publisher"],
          using: "other"
        )

        expect_db_query_count(1) { prefetcher.execute }

        records[0].get_related_object_variable(:publisher).should eq publisher_1
        records[1].get_related_object_variable(:publisher).should eq publisher_2
      end

      it "allows to prefetch a single many-to-many relation" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Def Doe")
        author_3 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Ghi Doe")
        author_4 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Jkl Doe")
        author_5 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Mno Doe")
        Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Pqr Doe")

        book_1 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Abc")
        book_2 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Def")
        book_3 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Ghi")

        book_1.authors.using(:other).add(author_1, author_3)
        book_2.authors.using(:other).add(author_2, author_3)
        book_3.authors.using(:other).add(author_4, author_5)

        records = Marten::DB::Query::PrefetcherSpec::Book.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["authors"],
          using: "other"
        )

        expect_db_query_count(2) { prefetcher.execute }

        records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
        records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2, author_3]
        records[2].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_4, author_5]
      end

      it "allows to prefetch a single reverse one-to-one relation" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Def Doe")

        pseudonym_1 = Marten::DB::Query::PrefetcherSpec::Pseudonym.using(:other).create!(author: author_1, name: "Abc")
        pseudonym_2 = Marten::DB::Query::PrefetcherSpec::Pseudonym.using(:other).create!(author: author_2, name: "Def")

        records = Marten::DB::Query::PrefetcherSpec::Author.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["pseudonym"],
          using: "other"
        )

        expect_db_query_count(1) { prefetcher.execute }

        records[0].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_1
        records[1].get_reverse_related_object_variable(:pseudonym).should eq pseudonym_2
      end

      it "allows to prefetch a single reverse many-to-one relation" do
        publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).create!(name: "Abc")
        publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).create!(name: "Def")

        author_1 = Marten::DB::Query::PrefetcherSpec::Author
          .using(:other)
          .create!(name: "Abc Doe", publisher: publisher_1)
        author_2 = Marten::DB::Query::PrefetcherSpec::Author
          .using(:other)
          .create!(name: "Def Doe", publisher: publisher_2)
        author_3 = Marten::DB::Query::PrefetcherSpec::Author
          .using(:other)
          .create!(name: "Ghi Doe", publisher: publisher_1)

        records = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["authors"],
          using: "other"
        )

        expect_db_query_count(1) { prefetcher.execute }

        records[0].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_1, author_3]
        records[1].authors.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [author_2]
      end

      it "allows to prefetch a single reverse many-to-many relation" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Def Doe")
        author_3 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Ghi Doe")
        author_4 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Jkl Doe")
        author_5 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Mno Doe")
        Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Pqr Doe")

        book_1 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Abc")
        book_2 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Def")
        book_3 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Ghi")

        book_1.authors.using(:other).add(author_1, author_3)
        book_2.authors.using(:other).add(author_2, author_3)
        book_3.authors.using(:other).add(author_4, author_5)

        records = Marten::DB::Query::PrefetcherSpec::Author.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["books"],
          using: "other"
        )

        expect_db_query_count(2) { prefetcher.execute }

        records[0].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1]
        records[1].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2]
        records[2].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
        records[3].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
        records[4].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
        records[5].books.result_cache.try(&.empty?).should be_true
      end

      it "can prefetch many relations" do
        publisher_1 = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).create!(name: "Abc")
        publisher_2 = Marten::DB::Query::PrefetcherSpec::Publisher.using(:other).create!(name: "Def")

        author_1 = Marten::DB::Query::PrefetcherSpec::Author
          .using(:other)
          .create!(name: "Abc Doe", publisher: publisher_1)
        author_2 = Marten::DB::Query::PrefetcherSpec::Author
          .using(:other)
          .create!(name: "Def Doe", publisher: publisher_2)
        author_3 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Ghi Doe")
        author_4 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Jkl Doe")
        author_5 = Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Mno Doe")
        Marten::DB::Query::PrefetcherSpec::Author.using(:other).create!(name: "Pqr Doe")

        book_1 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Abc")
        book_2 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Def")
        book_3 = Marten::DB::Query::PrefetcherSpec::Book.using(:other).create!(title: "Ghi")

        book_1.authors.using(:other).add(author_1, author_3)
        book_2.authors.using(:other).add(author_2, author_3)
        book_3.authors.using(:other).add(author_4, author_5)

        records = Marten::DB::Query::PrefetcherSpec::Author.using(:other).order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["publisher", "books"],
          using: "other"
        )

        expect_db_query_count(3) { prefetcher.execute }

        records[0].get_related_object_variable(:publisher).should eq publisher_1
        records[1].get_related_object_variable(:publisher).should eq publisher_2
        records[2].get_related_object_variable(:publisher).should be_nil
        records[3].get_related_object_variable(:publisher).should be_nil
        records[4].get_related_object_variable(:publisher).should be_nil
        records[5].get_related_object_variable(:publisher).should be_nil

        records[0].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1]
        records[1].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_2]
        records[2].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_1, book_2]
        records[3].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
        records[4].books.result_cache.try(&.sort_by(&.pk!.to_s)).should eq [book_3]
        records[5].books.result_cache.try(&.empty?).should be_true
      end

      it "uses a custom query set that filters records when prefetching" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
        author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Muster")
        author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")
        author_5 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Mno Muster")
        Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

        book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
        book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
        book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

        book_1.authors.add(author_1, author_3)
        book_2.authors.add(author_2, author_3)
        book_3.authors.add(author_4, author_5)

        records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["authors"],
          using: nil,
          custom_query_sets: {
            "authors" => Marten::DB::Query::PrefetcherSpec::Author
              .filter(name__contains: "Muster").as(Marten::DB::Query::Set::Any),
          }
        )

        expect_db_query_count(2) { prefetcher.execute }

        records[0].authors.result_cache.should eq [author_3]
        records[1].authors.result_cache.should eq [author_3]
        records[2].authors.result_cache.should eq [author_5]
      end

      it "doesn't use a custom query if none is specified for that relation" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
        author_3 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Ghi Muster")
        author_4 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Jkl Doe")
        author_5 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Mno Muster")
        Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

        book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")
        book_2 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Def")
        book_3 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Ghi")

        book_1.authors.add(author_1, author_3)
        book_2.authors.add(author_2, author_3)
        book_3.authors.add(author_4, author_5)

        records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["authors"],
          using: nil,
          custom_query_sets: {
            "conferences" => Marten::DB::Query::PrefetcherSpec::Conference
              .filter(name__contains: "Crystal").as(Marten::DB::Query::Set::Any),
          }
        )

        expect_db_query_count(2) { prefetcher.execute }

        records[0].authors.result_cache.should eq [author_1, author_3]
        records[1].authors.result_cache.should eq [author_2, author_3]
        records[2].authors.result_cache.should eq [author_4, author_5]
      end

      it "raises if an incompatible query set is used for the custom query" do
        author_1 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Abc Doe")
        author_2 = Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Def Doe")
        Marten::DB::Query::PrefetcherSpec::Author.create!(name: "Pqr Doe")

        book_1 = Marten::DB::Query::PrefetcherSpec::Book.create!(title: "Abc")

        book_1.authors.add(author_1, author_2)

        records = Marten::DB::Query::PrefetcherSpec::Book.order(:pk).to_a

        prefetcher = Marten::DB::Query::Prefetcher.new(
          records: Array(Marten::DB::Model).new.concat(records),
          relations: ["authors"],
          using: nil,
          custom_query_sets: {
            "authors" => Marten::DB::Query::PrefetcherSpec::Bio
              .filter(content__contains: "Muster").as(Marten::DB::Query::Set::Any),
          }
        )

        expect_raises(
          Marten::DB::Errors::UnmetQuerySetCondition,
          "Can't prefetch :authors using Marten::DB::Query::PrefetcherSpec::Bio query set"
        ) do
          prefetcher.execute
        end
      end
    end
  end
end
