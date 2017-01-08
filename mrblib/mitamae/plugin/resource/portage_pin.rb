module ::MItamae
  module Plugin
    module Resource
      class PortagePin < ::MItamae::Resource::Base
        define_attribute :name, type: String, default_name: true
        define_attribute :action, default: :pin
        define_attribute :version, type: String, required: true
        define_attribute :mask_target, type: [String, NilClass]
        define_attribute :unmask_target, type: [String, NilClass]

        self.available_actions = [:pin, :unpin]
      end
    end
  end
end
