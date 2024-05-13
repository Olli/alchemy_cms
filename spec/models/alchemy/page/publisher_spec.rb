# frozen_string_literal: true

require "rails_helper"
require "timecop"

RSpec.describe Alchemy::Page::Publisher do
  describe "#publish!" do
    let(:current_time) { Time.current.change(usec: 0) }
    let(:page) do
      create(:alchemy_page,
        public_on: public_on,
        public_until: public_until,
        published_at: published_at)
    end
    let(:published_at) { nil }
    let(:public_on) { nil }
    let(:public_until) { nil }
    let(:publisher) { described_class.new(page) }

    subject(:publish) { publisher.publish!(public_on: current_time) }

    around do |example|
      Timecop.freeze(current_time) do
        example.run
      end
    end

    shared_context "with elements" do
      let(:page) do
        create(:alchemy_page, autogenerate_elements: true).tap do |page|
          page.draft_version.elements.first.update!(public: false)
        end
      end
    end

    it "creates a public version" do
      expect { publish }.to change { page.versions.published.count }.by(1)
    end

    it "updates the public_on timestamp" do
      expect {
        publish
      }.to change {
        page.reload.public_on
      }.to(current_time)
    end

    context "with elements" do
      include_context "with elements"

      it "copies all published elements to page version" do
        publish
        expect(page.reload.public_version.elements.count).to eq(2)
      end
    end

    context "with published version existing" do
      let(:yesterday) { Date.yesterday.to_time }
      let!(:public_version) do
        create(:alchemy_page_version, :with_elements, element_count: 3, public_on: yesterday, page: page)
      end

      let!(:nested_element) do
        create(:alchemy_element, page_version: public_version, parent_element: public_version.elements.first)
      end

      it "does not change current public versions public on date" do
        expect { publish }.to_not change(page.public_version, :public_on)
      end

      it "updates public version's updated_at timestamp" do
        # Need to do this here, because the nested element touches the version on creation.
        public_version.update_columns(updated_at: yesterday)
        expect { publish }.to change(page.public_version, :updated_at)
      end

      it "does not create another public version" do
        expect { publish }.to_not change(page.versions, :count)
      end

      context "with elements" do
        include_context "with elements"

        it "copies all published elements to public version" do
          publish
          expect(public_version.reload.elements.count).to eq(2)
        end
      end
    end

    context "with publish targets" do
      let(:target) { Class.new(ActiveJob::Base) }

      around do |example|
        Alchemy.publish_targets << target
        example.run
        Alchemy.instance_variable_set(:@_publish_targets, nil)
      end

      it "performs each target" do
        expect(target).to receive(:perform_later).with(page)
        publish
      end
    end

    context "in parallel" do
      before do
        # another publisher - instance created a mutex entry and locked the page
        Alchemy::PageMutex.create(page: page, created_at: 5.seconds.ago)
      end

      it "fails, if another process locked the page" do
        expect { publish }.to raise_error Alchemy::PageMutex::LockFailed
      end

      context "another page" do
        let(:another_page) { create(:alchemy_page) }
        let(:publisher) { described_class.new(another_page) }

        it "should allow the publishing of another page" do
          expect { publish }.to change { another_page.versions.published.count }.by(1)
        end
      end
    end
  end
end
