module ::MItamae
  module Plugin
    module Resource
      class PortagePackage < ::MItamae::Resource::Base
        include MItamaePluginResourcePortage::ResourceBases::Portage

        define_attribute :action, default: :install
        define_attribute :emerge_cmd, type: String, default: '/usr/bin/emerge'
        define_attribute :eix_cmd, type: String, default: '/usr/bin/eix'
        # define_attribute :eix_update_cmd, type: String, default: '/usr/bin/eix-update'

        define_attribute :noreplace, type: [TrueClass, FalseClass], default: true
        define_attribute :oneshot, type: [TrueClass, FalseClass], default: false

        self.available_actions = [:install, :update, :remove]
      end
    end
  end
end
