# frozen_string_literal: true
require "spec_helper"
require "graphql/types/iso_8601_date"
describe GraphQL::Types::ISO8601Date do
  module DateTest
    class DateObject < GraphQL::Schema::Object
      field :year, Integer, null: false
      field :month, Integer, null: false
      field :day, Integer, null: false
      field :iso8601, GraphQL::Types::ISO8601Date, null: false, method: :itself
    end

    class Query < GraphQL::Schema::Object
      field :parse_date, DateObject do
        argument :date, GraphQL::Types::ISO8601Date
      end

      field :parse_date_time, DateObject do
        argument :date, GraphQL::Types::ISO8601Date
      end

      field :parse_date_string, DateObject do
        argument :date, GraphQL::Types::ISO8601Date
      end

      field :parse_date_time_string, DateObject do
        argument :date, GraphQL::Types::ISO8601Date
      end

      field :serialize_date_default_argument, DateObject do
        argument(
          :date,
          GraphQL::Types::ISO8601Date,
          required: false,
          default_value: Date.today
          )
      end

      field :serialize_date_time_default_argument, DateObject do
        argument(
          :date,
          GraphQL::Types::ISO8601Date,
          required: false,
          default_value: DateTime.now
          )
      end

      field :serialize_time_default_argument, DateObject do
        argument(
          :date,
          GraphQL::Types::ISO8601Date,
          required: false,
          default_value: Time.now
          )
      end

      field :serialize_string_default_argument, DateObject do
        argument(
          :date,
          GraphQL::Types::ISO8601Date,
          required: false,
          default_value: '1951-09-23'
          )
      end

      def parse_date(date:)
        # Resolve a Date object
        Date.parse(date.iso8601)
      end

      def parse_date_time(date:)
        # Resolve a DateTime object
        DateTime.parse(date.iso8601)
      end

      def parse_date_string(date:)
        # Resolve a Date string
        Date.parse(date.iso8601).iso8601
      end

      def parse_date_time_string(date:)
        # Resolve a DateTime string
        DateTime.parse(date.iso8601).iso8601
      end

      def serialize_date_default_argument(date:)
        date
      end

      def serialize_date_time_default_argument(date:)
        date
      end

      def serialize_time_default_argument(date:)
        date
      end

      def serialize_string_default_argument(date:)
        date
      end
    end

    class Schema < GraphQL::Schema
      query(Query)

      def self.type_error(err, ctx)
        if ctx[:raise_type_error]
          raise GraphQL::ExecutionError, "A type error was raised"
        else
          super
        end
      end
    end
  end


  describe "as an input" do

    def parse_date(date_str, context: {})
      query_str = <<-GRAPHQL
      query($date: ISO8601Date!){
        parseDate(date: $date) {
          year
          month
          day
        }
      }
      GRAPHQL
      full_res = DateTest::Schema.execute(query_str, context: context, variables: { date: date_str })
      full_res["errors"] || full_res["data"]["parseDate"]
    end

    it "parses valid dates" do
      res = parse_date("2018-06-07")
      expected_res = {
        "year" => 2018,
        "month" => 6,
        "day" => 7,
      }
      assert_equal(expected_res, res)
    end

    it "adds an error for invalid dates" do
      expected_errors = ["Variable $date of type ISO8601Date! was provided invalid value"]

      assert_equal expected_errors, parse_date("2018-26-07").map { |e| e["message"] }
      assert_equal expected_errors, parse_date("xyz").map { |e| e["message"] }
      assert_equal expected_errors, parse_date(nil).map { |e| e["message"] }
      assert_equal expected_errors, parse_date([1, 2, 3]).map { |e| e["message"] }
      assert_equal "A type error was raised", parse_date("blah", context: { raise_type_error: true })[0]["extensions"]["problems"][0]["explanation"]
      assert_equal "Could not coerce value \"blah\" to ISO8601Date", parse_date("blah", context: { raise_type_error: false })[0]["extensions"]["problems"][0]["explanation"]
    end


    it "handles array inputs gracefully" do
      query_str = <<-GRAPHQL
        {
          parseDate(date: ["A", "B", "C"]) {
            year
          }
        }
      GRAPHQL

      res = DateTest::Schema.execute(query_str)
      expected_message = "Argument 'date' on Field 'parseDate' has an invalid value ([\"A\", \"B\", \"C\"]). Expected type 'ISO8601Date!'."
      assert_equal expected_message, res["errors"].first["message"]
    end
  end

  describe "as an argument default value" do

    it 'serializes a Date object as an ISO8601 Date string' do
      query_str = <<-GRAPHQL
      query {
        serializeDateDefaultArgument {
          iso8601
        }
      }
      GRAPHQL
      full_res = DateTest::Schema.execute(query_str)

      date_str = Date.today.iso8601
      assert_equal date_str, full_res["data"]["serializeDateDefaultArgument"]["iso8601"]
    end

    it 'serializes a DateTime object as an ISO8601 Date string' do
      query_str = <<-GRAPHQL
      query {
        serializeDateTimeDefaultArgument {
          iso8601
        }
      }
      GRAPHQL
      full_res = DateTest::Schema.execute(query_str)

      date_str = DateTime.now.to_date.iso8601
      assert_equal date_str, full_res["data"]["serializeDateTimeDefaultArgument"]["iso8601"]
    end

    it 'serializes a Time object as an ISO8601 Date string' do
      query_str = <<-GRAPHQL
      query {
        serializeTimeDefaultArgument {
          iso8601
        }
      }
      GRAPHQL
      full_res = DateTest::Schema.execute(query_str)

      date_str = Time.new.to_date.iso8601
      assert_equal date_str, full_res["data"]["serializeTimeDefaultArgument"]["iso8601"]
    end

    it 'serializes a string object as an ISO8601 Date string' do
      query_str = <<-GRAPHQL
      query {
        serializeStringDefaultArgument {
          iso8601
        }
      }
      GRAPHQL
      full_res = DateTest::Schema.execute(query_str)

      date_str = '1951-09-23'
      assert_equal date_str, full_res["data"]["serializeStringDefaultArgument"]["iso8601"]
    end
  end

  describe "as an output" do
    let(:date_str) { "2010-02-02" }
    let(:query_str) do
      <<-GRAPHQL
      query($date: ISO8601Date!){
        parseDate(date: $date) {
          iso8601
        }
        parseDateTime(date: $date) {
          iso8601
        }
        parseDateString(date: $date) {
          iso8601
        }
        parseDateTimeString(date: $date) {
          iso8601
        }
      }
      GRAPHQL
    end
    let(:full_res) { DateTest::Schema.execute(query_str, variables: { date: date_str }) }

    it 'serializes a Date object as an ISO8601 Date string' do
      assert_equal date_str, full_res["data"]["parseDate"]["iso8601"]
    end

    it 'serializes a DateTime object as an ISO8601 Date string' do
      assert_equal date_str, full_res["data"]["parseDateTime"]["iso8601"]
    end

    it 'serializes a Date string as an ISO8601 Date string' do
      assert_equal date_str, full_res["data"]["parseDateString"]["iso8601"]
    end

    it 'serializes a DateTime string as an ISO8601 Date string' do
      assert_equal date_str, full_res["data"]["parseDateTimeString"]["iso8601"]
    end
  end

  describe "structure" do
    it "is in introspection" do
      introspection_res = DateTest::Schema.execute <<-GRAPHQL
      {
        __type(name: "ISO8601Date") {
          name
          kind
        }
      }
      GRAPHQL

      expected_res = { "name" => "ISO8601Date", "kind" => "SCALAR"}
      assert_equal expected_res, introspection_res["data"]["__type"]
    end
  end
end
