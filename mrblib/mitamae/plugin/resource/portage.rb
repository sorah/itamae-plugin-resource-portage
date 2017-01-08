module ::MItamae
  module Plugin
    module Resource
      class Portage < ::MItamae::Resource::Base
        include MItamaePluginResourcePortage::ResourceBases::Portage

        define_attribute :action, default: :install

        define_attribute :emerge_cmd, type: String, default: '/usr/bin/emerge'
        define_attribute :eix_cmd, type: String, default: '/usr/bin/eix'
        # define_attribute :eix_update_cmd, type: String, default: '/usr/bin/eix-update'

        define_attribute :package_use_file, type: String
        define_attribute :package_mask_file, type: String
        define_attribute :package_unmask_file, type: String
        define_attribute :package_accept_keywords_file, type: String

        define_attribute :unmask, type: [NilClass, TrueClass, FalseClass]
        define_attribute :pin, type: [TrueClass, FalseClass], default: false

        define_attribute :noreplace, type: [TrueClass, FalseClass], default: true
        define_attribute :oneshot, type: [TrueClass, FalseClass], default: false

        define_attribute :flags, type: [Array, String]
        define_attribute :keywords, type: [Array, String]

        self.available_actions = [:install, :update, :remove]
      end
    end
  end
end
