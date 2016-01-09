require 'itamae-plugin-resource-portage/portage_file_resource_base'

module ItamaePluginResourcePortage
  module Resources
    class PortageUse < PortageFileResourceBase
      define_attribute :flags, type: Array

      def value
        attributes.flags
      end

      def target_default_directory
        "/etc/portage/package.use"
      end
    end
  end 
end
