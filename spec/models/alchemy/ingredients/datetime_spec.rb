# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alchemy::Ingredients::Datetime do
  it_behaves_like "an alchemy ingredient"

  let(:element) { build(:alchemy_element) }

  let(:datetime_ingredient) do
    described_class.new(
      element: element,
      type: described_class.name,
      role: "date",
      value: "01.04.2021"
    )
  end

  describe ".allowed_settings" do
    it "sets allowed_settings" do
      expect(described_class.allowed_settings).to eq([:date_format, :input_type])
    end
  end

  describe "value" do
    subject(:value) { datetime_ingredient.value }

    it "returns a time object" do
      is_expected.to be_an(Time)
      is_expected.to eq("01.04.2021")
    end

    it "timezone is UTC" do
      expect(value.zone).to eq("UTC")
    end

    context "without value" do
      let(:datetime_ingredient) do
        described_class.new(
          element: element,
          type: described_class.name,
          role: "date"
        )
      end

      it { is_expected.to be_nil }
    end
  end

  describe "preview_text" do
    subject { datetime_ingredient.preview_text }

    it "returns a localized date" do
      is_expected.to eq("2021-04-01")
    end

    context "without date" do
      let(:datetime_ingredient) do
        described_class.new(
          element: element,
          type: described_class.name,
          role: "date"
        )
      end

      it { is_expected.to eq "" }
    end
  end
end
