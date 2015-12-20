require 'spec_helper'
require 'itamae'
require 'fileutils'
require 'itamae-plugin-resource-portage/resources/portage_file_base'

describe ItamaePluginResourcePortage::Resources::PortageFileBase do
  let(:tmpdir) { Pathname.new(Dir.mktmpdir('portagefilebasespec')) }
  let(:target_default_directory) { tmpdir.join('target').tap(&:mkpath) }
  let(:target_file) { target_default_directory.join('itamae') }
  let(:klass) do
    Class.new(described_class) do
      def self.name
        'PortageFileSpecTestResource'
      end

      def value
        ['xxx']
      end

      def target_default_directory
        self.class.instance_variable_get(:@target_default_directory)
      end
    end.tap do |k|
      k.instance_variable_set(:@target_default_directory, target_default_directory.to_s)
    end
  end

  let(:backend) { Itamae::Backend.create(:local) }
  let(:handler) { double('handler').tap { |_| allow(_).to receive(:event) { |*__, &b| b[] if b } } }
  let(:runner) { double('runner', tmpdir: tmpdir.join('runner').tap(&:mkpath), options: {}, dry_run?: false, backend: backend, handler: handler) }
  let(:recipe) { double('recipe', runner: runner, children: double('children', subscribing: [])) }

  describe "with simple usage" do
    subject(:resource) do
      klass.new(recipe, 'pkgname') do
      end
    end

    describe ":add action" do
      context "when target directory is file" do
        before do
          FileUtils.remove_entry_secure target_default_directory
          File.write target_default_directory.to_s, "\n"
        end

        it "uses it as file" do
          resource.run(:add)
          expect(target_default_directory.read).to match(/^pkgname xxx$/)
        end
      end

      context "when file doesn't exist" do
        it "creates file" do
          expect {
            resource.run(:add)
          }.to change { target_file.exist? }.from(false).to(true)

          expect(target_file.read).to match(/^pkgname xxx$/)
        end
      end

      context "when file already exist" do
        before do
          File.write target_file.to_s, "\n"
        end

        it "uses file" do
          expect {
            resource.run(:add)
          }.to change { /^pkgname xxx$/ === target_file.read }.from(false).to(true)
        end
      end

      context "when file already exist and the file has same content" do
        before do
          File.write target_file.to_s, "pkgname xxx\n"
        end

        it "doesn't make change" do
          expect {
            resource.run(:add)
          }.not_to change { target_file.read }
        end
      end

      context "when file already exist and the file has different content" do
        before do
          File.write target_file.to_s, "pkgname yyy\n"
        end

        it "updates file" do
          resource.run(:add)
          expect(target_file.read).not_to match(/^pkgname yyy$/)
          expect(target_file.read).to match(/^pkgname xxx$/)
        end
      end

      context "when file already exist and the file has some existing content" do
        before do
          File.write target_file.to_s, "otherpkg yyy\n"
        end

        it "adds line" do
          resource.run(:add)

          expect(target_file.read).to match(/^otherpkg yyy$/)
          expect(target_file.read).to match(/^pkgname xxx$/)
        end
      end
    end
    describe ":remove action" do
      context "when target directory is file" do
        before do
          FileUtils.remove_entry_secure target_default_directory
          File.write target_default_directory.to_s, "pkgname xxx\n"
        end

        it "uses it as file" do
          resource.run(:remove)
          expect(target_default_directory.read).not_to match(/^pkgname xxx$/)
        end
      end

      context "when file doesn't exist" do
        it "does nothing" do
          expect {
            resource.run(:remove)
          }.not_to change { target_file.exist? }
        end
      end

      context "when file exist and file has content" do
        before do
          File.write target_file.to_s, "pkgname xxx\n"
        end

        it "uses file" do
          resource.run(:remove)
          expect(target_file.read).not_to match(/^pkgname xxx$/)
        end
      end

      context "when file exist but file doesn't have target content" do
        before do
          File.write target_file.to_s, "otherpkg yyy\n"
        end

        it "doesn't make change" do
          expect {
            resource.run(:remove)
          }.not_to change { target_file.read }
        end
      end

      context "when file already exist and the file has some existing content" do
        before do
          File.write target_file.to_s, "otherpkg yyy\npkgname xxx\n"
        end

        it "adds line" do
          resource.run(:remove)

          expect(target_file.read).to match(/^otherpkg yyy$/)
          expect(target_file.read).not_to match(/^pkgname xxx$/)
        end
      end
    end
  end
end
