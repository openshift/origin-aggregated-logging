# coding: utf-8
# frozen_string_literal: true

RSpec.describe HTTP::FormData::Urlencoded do
  let(:data) { { "foo[bar]" => "test" } }
  subject(:form_data) { HTTP::FormData::Urlencoded.new data }

  describe "#content_type" do
    subject { form_data.content_type }
    it { is_expected.to eq "application/x-www-form-urlencoded" }
  end

  describe "#content_length" do
    subject { form_data.content_length }
    it { is_expected.to eq form_data.to_s.bytesize }

    context "with unicode chars" do
      let(:data) { { "foo[bar]" => "тест" } }
      it { is_expected.to eq form_data.to_s.bytesize }
    end
  end

  describe "#to_s" do
    subject { form_data.to_s }
    it { is_expected.to eq "foo%5Bbar%5D=test" }

    context "with unicode chars" do
      let(:data) { { "foo[bar]" => "тест" } }
      it { is_expected.to eq "foo%5Bbar%5D=%D1%82%D0%B5%D1%81%D1%82" }
    end
  end
end
