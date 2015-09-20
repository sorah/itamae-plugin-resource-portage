require 'itamae-plugin-resource-portage/resources/portage_file_base'

module ItamaePluginResourcePortage
  module Resources
    class PortageUse < PortageFileBase
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
