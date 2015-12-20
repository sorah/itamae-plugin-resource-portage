require 'spec_helper'
require 'itamae'
require 'fileutils'
require 'itamae-plugin-resource-portage/resources/portage_mask'
require 'itamae-plugin-resource-portage/resources/portage_unmask'
require 'itamae-plugin-resource-portage/resources/portage_pin'

describe ItamaePluginResourcePortage::Resources::PortagePin do
  let(:tmpdir) { Pathname.new(Dir.mktmpdir('portagepinspec')) }
  let(:mask_dir) { tmpdir.join('mask').tap(&:mkpath) }
  let(:unmask_dir) { tmpdir.join('unmask').tap(&:mkpath) }
  let(:mask_file) { mask_dir.join('itamae') }
  let(:unmask_file) { unmask_dir.join('itamae') }

  let(:backend) { Itamae::Backend.create(:local) }
  let(:handler) { double('handler').tap { |_| allow(_).to receive(:event) { |*__, &b| b[] if b } } }
  let(:runner) { double('runner', tmpdir: tmpdir.join('runner').tap(&:mkpath), options: {}, dry_run?: false, backend: backend, handler: handler) }
  let(:recipe) { double('recipe', runner: runner, children: double('children', subscribing: [])) }

  before do
    allow_any_instance_of(ItamaePluginResourcePortage::Resources::PortageUnmask).to receive(:target_default_directory).and_return(unmask_dir.to_s)
    allow_any_instance_of(ItamaePluginResourcePortage::Resources::PortageMask).to receive(:target_default_directory).and_return(mask_dir.to_s)
  end

  describe ":pin action" do
    subject(:resource) { described_class.new(recipe, 'pkgname') { version('1.2.3') } } 

    it "masks entire package and unmasks specified version" do
      resource.run(:pin)

      expect(mask_file.read).to match(/^pkgname$/)
      expect(unmask_file.read).to match(/^=pkgname-1.2.3$/)
    end
  end

  describe ":unpin action" do
    subject(:resource) { described_class.new(recipe, 'pkgname') { version('1.2.3') } } 

    before do
      File.write mask_file.to_s, "pkgname\n"
      File.write unmask_file.to_s, "=pkgname-1.2.3\n"
    end

    it "masks entire package and unmasks specified version" do
      resource.run(:unpin)

      expect(mask_file.read).not_to match(/^pkgname$/)
      expect(unmask_file.read).not_to match(/^=pkgname-1.2.3$/)
    end
  end
end

