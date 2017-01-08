module ::MItamaePluginResourcePortage
  module ResourceBases
    module Portage
      def self.included(klass)
        klass.instance_eval do
          define_attribute :name, type: String, default_name: true

          define_attribute :version, type: String
          define_attribute :slot, type: String
          define_attribute :op, type: String
          define_attribute :atom, type: String
        end
      end
    end
  end
end
