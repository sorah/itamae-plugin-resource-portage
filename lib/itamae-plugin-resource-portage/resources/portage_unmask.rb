require 'itamae-plugin-resource-portage/portage_file_resource_base'

module ItamaePluginResourcePortage
  module Resources
    class PortageUnmask < PortageFileResourceBase
      def value
        true
      end

      def target_default_directory
        "/etc/portage/package.unmask"
      end
    end
  end 
end
