require 'itamae-plugin-resource-portage/resources/portage_file_base'

module ItamaePluginResourcePortage
  module Resources
    class PortageUnmask < PortageFileBase
      def value
        true
      end

      def target_default_directory
        "/etc/portage/package.unmask"
      end
    end
  end 
end
