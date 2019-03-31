# frozen_string_literal: true

RSpec.describe HTTP::FormData::Multipart do
  let(:file)          { HTTP::FormData::File.new fixture "the-http-gem.info" }
  let(:params)        { { :foo => :bar, :baz => file } }
  let(:boundary)      { /-{21}[a-f0-9]{42}/ }
  subject(:form_data) { HTTP::FormData::Multipart.new params }

  describe "#content_type" do
    subject { form_data.content_type }

    let(:content_type) { %r{^multipart\/form-data; boundary=#{boundary}$} }

    it { is_expected.to match(content_type) }
  end

  describe "#content_length" do
    subject { form_data.content_length }
    it { is_expected.to eq form_data.to_s.bytesize }
  end

  describe "#to_s" do
    def disposition(params)
      params = params.map { |k, v| "#{k}=#{v.inspect}" }.join("; ")
      "Content-Disposition: form-data; #{params}"
    end

    let(:crlf) { "\r\n" }

    it "properly generates multipart data" do
      boundary_value = form_data.content_type[/(#{boundary})$/, 1]

      expect(form_data.to_s).to eq [
        "--#{boundary_value}#{crlf}",
        "#{disposition 'name' => 'foo'}#{crlf}",
        "#{crlf}bar#{crlf}",
        "--#{boundary_value}#{crlf}",
        "#{disposition 'name' => 'baz', 'filename' => file.filename}#{crlf}",
        "Content-Type: #{file.mime_type}#{crlf}",
        "#{crlf}#{file}#{crlf}",
        "--#{boundary_value}--"
      ].join("")
    end

    context "with filename set to nil" do
      let(:part) { HTTP::FormData::Part.new("s", :filename => nil) }
      let(:form_data) { HTTP::FormData::Multipart.new(:foo => part) }

      it "doesn't include a filename" do
        boundary_value = form_data.content_type[/(#{boundary})$/, 1]

        expect(form_data.to_s).to eq [
          "--#{boundary_value}#{crlf}",
          "#{disposition 'name' => 'foo'}#{crlf}",
          "#{crlf}s#{crlf}",
          "--#{boundary_value}--"
        ].join("")
      end
    end
  end
end
