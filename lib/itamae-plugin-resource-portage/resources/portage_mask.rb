require 'itamae-plugin-resource-portage/resources/portage_file_base'

module ItamaePluginResourcePortage
  module Resources
    class PortageMask < PortageFileBase
      def value
        true
      end

      def target_default_directory
        "/etc/portage/package.mask"
      end
    end
  end 
end
