module ::MItamaePluginResourcePortage
  module ResourceBases
    module PortageFile
      def self.included(klass)
        klass.instance_eval do
          define_attribute :action, default: :add
          define_attribute :target, type: String
          self.available_actions = [:add, :remove]
        end
      end
    end
  end
end
