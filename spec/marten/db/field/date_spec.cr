require "./spec_helper"

describe Marten::DB::Field::Date do
  describe "::new" do
    it "initializes a date time field instance with the expected defaults" do
      field = Marten::DB::Field::Date.new("my_field")
      field.id.should eq "my_field"
      field.primary_key?.should be_false
      field.blank?.should be_false
      field.null?.should be_false
      field.unique?.should be_false
      field.db_column.should eq field.id
      field.index?.should be_false
      field.auto_now?.should be_false
      field.auto_now_add?.should be_false
    end

    it "sets the field as blankable if auto_now is set to true" do
      field = Marten::DB::Field::Date.new("my_field", auto_now: true)
      field.auto_now?.should be_true
      field.blank?.should be_true
    end

    it "sets the field as blankable if auto_now_add is set to true" do
      field = Marten::DB::Field::Date.new("my_field", auto_now_add: true)
      field.auto_now_add?.should be_true
      field.blank?.should be_true
    end
  end

  describe "#auto_now?" do
    it "returns true if auto_now is set to true" do
      field = Marten::DB::Field::Date.new("my_field", auto_now: true)
      field.auto_now?.should be_true
    end

    it "returns false if auto_now is set to false" do
      field = Marten::DB::Field::Date.new("my_field", auto_now: false)
      field.auto_now?.should be_false
    end
  end

  describe "#auto_now_add?" do
    it "returns true if auto_now_add is set to true" do
      field = Marten::DB::Field::Date.new("my_field", auto_now_add: true)
      field.auto_now_add?.should be_true
    end

    it "returns false if auto_now_add is set to false" do
      field = Marten::DB::Field::Date.new("my_field", auto_now_add: false)
      field.auto_now_add?.should be_false
    end
  end

  describe "#from_db" do
    it "is able to process a time object" do
      time = Time.local
      field = Marten::DB::Field::Date.new("my_field")
      field.from_db(time).should be_a Time
      field.from_db(time).not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
    end

    it "is able to process a nil value" do
      field = Marten::DB::Field::Date.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "is able to process a date-only string" do
      field = Marten::DB::Field::Date.new("my_field")
      value = field.from_db("2017-09-28")

      value.should be_a Time
      value.not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
      value.not_nil!.to_s("%F").should eq "2017-09-28"
      value.not_nil!.hour.should eq 0
      value.not_nil!.minute.should eq 0
      value.not_nil!.second.should eq 0
    end

    it "is able to process a datetime string without subseconds" do
      field = Marten::DB::Field::Date.new("my_field")
      value = field.from_db("2017-09-28 02:57:14")

      value.should be_a Time
      value.not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
      value.not_nil!.to_s("%F").should eq "2017-09-28"
      value.not_nil!.hour.should eq 0
      value.not_nil!.minute.should eq 0
      value.not_nil!.second.should eq 0
    end

    it "is able to process a datetime string with subseconds" do
      field = Marten::DB::Field::Date.new("my_field")
      value = field.from_db("2017-09-28 02:57:14.839000")

      value.should be_a Time
      value.not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
      value.not_nil!.to_s("%F").should eq "2017-09-28"
      value.not_nil!.hour.should eq 0
      value.not_nil!.minute.should eq 0
      value.not_nil!.second.should eq 0
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Date.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end

    it "returns the stored date in the project time zone if the time zone has a negative UTC offset" do
      los_angeles_time_zone = Time::Location.load("America/Los_Angeles")

      with_overridden_setting("time_zone", los_angeles_time_zone) do
        field = Marten::DB::Field::Date.new("my_field")

        field.from_db(Time.utc(2026, 7, 31)).should eq Time.local(2026, 7, 31, location: los_angeles_time_zone)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a date time from a DB result set" do
      field = Marten::DB::Field::Date.new("my_field")

      Marten::DB::Connection.default.open do |db|
        for_postgresql do
          db.query("SELECT DATE '2017-09-28'") do |rs|
            rs.each do
              value = field.from_db_result_set(rs)
              value.should be_a Time
              value.not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
              value.not_nil!.hour.should eq 0
              value.not_nil!.minute.should eq 0
              value.not_nil!.second.should eq 0
            end
          end
        end

        for_mysql do
          db.query("SELECT CAST('2017-09-28' AS DATE)") do |rs|
            rs.each do
              value = field.from_db_result_set(rs)
              value.should be_a Time
              value.not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
              value.not_nil!.hour.should eq 0
              value.not_nil!.minute.should eq 0
              value.not_nil!.second.should eq 0
            end
          end
        end

        for_sqlite do
          db.query("SELECT '2017-09-28'") do |rs|
            rs.each do
              value = field.from_db_result_set(rs)
              value.should be_a Time
              value.not_nil!.zone.name.should eq Marten.settings.time_zone.to_s
              value.not_nil!.hour.should eq 0
              value.not_nil!.minute.should eq 0
              value.not_nil!.second.should eq 0
            end
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::Date.new("my_field")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#prepare_save" do
    it "sets the current date if auto_now_add is set to true and the record is new" do
      user = TestUser.new
      field = Marten::DB::Field::Date.new("created_at", auto_now_add: true)

      user.created_at.should be_nil

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        field.prepare_save(user, true)
      end

      user.created_at.should eq time.at_beginning_of_day
    end

    it "does not persist the current date if auto_now_add is set to true and the record is not new" do
      user = TestUser.new
      field = Marten::DB::Field::Date.new("created_at", auto_now_add: true)

      user.created_at.should be_nil

      field.prepare_save(user, false)

      user.created_at.should be_nil
    end

    it "sets the current date if auto_now is set to true and the record is new" do
      user = TestUser.new
      field = Marten::DB::Field::Date.new("updated_at", auto_now: true)

      user.updated_at.should be_nil

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        field.prepare_save(user, true)
      end

      user.updated_at.should eq time.at_beginning_of_day
    end

    it "sets the current date if auto_now is set to true and the record is new" do
      user = TestUser.new
      field = Marten::DB::Field::Date.new("updated_at", auto_now: true)

      user.updated_at.should be_nil

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        field.prepare_save(user, false)
      end

      user.updated_at.should eq time.at_beginning_of_day
    end

    it "sets the current date in the project time zone" do
      los_angeles_time_zone = Time::Location.load("America/Los_Angeles")

      with_overridden_setting("time_zone", los_angeles_time_zone) do
        user = TestUser.new
        field = Marten::DB::Field::Date.new("created_at", auto_now_add: true)

        Timecop.freeze(Time.utc(2026, 11, 4, 3, 0, 0)) do
          field.prepare_save(user, true)
        end

        user.created_at.should eq Time.local(2026, 11, 3, location: los_angeles_time_zone)
      end
    end

    it "does not persist the current date if no auto option is used and the record is new" do
      user = TestUser.new
      field = Marten::DB::Field::Date.new("created_at")

      user.created_at.should be_nil

      field.prepare_save(user, true)

      user.created_at.should be_nil
    end

    it "does not persist the current date if no auto option is used and the record is not new" do
      user = TestUser.new
      field = Marten::DB::Field::Date.new("created_at")

      user.created_at.should be_nil

      field.prepare_save(user, false)

      user.created_at.should be_nil
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Date.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Date
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      default_dt = Time.local(2026, 7, 31, 14, 30, 0, location: Time::Location.load("Europe/Paris"))
      field = Marten::DB::Field::Date.new("my_field", db_column: "my_field_col", default: default_dt)
      column = field.to_column
      column.default.should eq Time.utc(2026, 7, 31)
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::Date.new("my_field")
      field.default.should be_nil
    end

    it "returns the configured default" do
      default_dt = Time.local
      field = Marten::DB::Field::Date.new("my_field", default: default_dt)
      field.default.should eq default_dt
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Date.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns a Time value if the initial value is a Time" do
      field = Marten::DB::Field::Date.new("my_field")

      time = Time.local(2026, 7, 31, 14, 30, 0, location: Time::Location.load("Europe/Paris"))
      field.to_db(time).should eq Time.utc(2026, 7, 31)
    end

    it "returns a value whose date is the local date if the time zone has a positive UTC offset" do
      paris_time_zone = Time::Location.load("Europe/Paris")

      with_overridden_setting("time_zone", paris_time_zone) do
        field = Marten::DB::Field::Date.new("my_field")
        time = Time.local(2026, 7, 31, 14, 30, 0, location: paris_time_zone)

        field.to_db(time).as(Time).to_s("%F").should eq "2026-07-31"
      end
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Date.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end

  describe "date values persistence" do
    ["Europe/Paris", "America/Los_Angeles", "Asia/Kolkata"].each do |time_zone_name|
      it "preserves the local date across saves and reads in #{time_zone_name}" do
        time_zone = Time::Location.load(time_zone_name)

        with_overridden_setting("time_zone", time_zone) do
          user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
          profile = TestUserProfile.create!(
            user: user,
            milestone_on: Time.local(2026, 7, 31, 22, 30, 0, location: time_zone)
          )

          2.times { TestUserProfile.get!(pk: profile.pk).save! }

          milestone_on = TestUserProfile.get!(pk: profile.pk).milestone_on!
          milestone_on.should eq Time.local(2026, 7, 31, location: time_zone)
        end
      end

      it "matches a saved date in lookups in #{time_zone_name}" do
        time_zone = Time::Location.load(time_zone_name)

        with_overridden_setting("time_zone", time_zone) do
          user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
          profile = TestUserProfile.create!(
            user: user,
            milestone_on: Time.local(2026, 7, 31, 22, 30, 0, location: time_zone)
          )
          date = Time.local(2026, 7, 31, location: time_zone)

          TestUserProfile.filter(milestone_on: date).to_a.should eq [profile]
          TestUserProfile.filter(milestone_on__in: [date]).to_a.should eq [profile]
          TestUserProfile.filter(milestone_on__gt: date).exists?.should be_false
          TestUserProfile.filter(milestone_on__lt: date).exists?.should be_false
        end
      end
    end

    it "preserves a date whose local midnight is skipped by a DST transition" do
      santiago_time_zone = Time::Location.load("America/Santiago")

      with_overridden_setting("time_zone", santiago_time_zone) do
        user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        profile = TestUserProfile.create!(
          user: user,
          milestone_on: Time.local(2026, 9, 6, 12, 0, 0, location: santiago_time_zone)
        )

        2.times { TestUserProfile.get!(pk: profile.pk).save! }

        TestUserProfile.get!(pk: profile.pk).milestone_on!.to_s("%F").should eq "2026-09-06"
      end
    end
  end
end
