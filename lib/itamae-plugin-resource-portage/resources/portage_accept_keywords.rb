require 'itamae-plugin-resource-portage/portage_file_resource_base'

module ItamaePluginResourcePortage
  module Resources
    class PortageAcceptKeywords < PortageFileResourceBase
      define_attribute :keywords, type: [String, Array, NilClass]

      def value
        attributes.keywords || default_accept_keywords
      end

      def default_accept_keywords
        @default_accept_keywords ||= begin
          eix_arch = backend.run_command(%w(eix --print ARCH), error: false)
          if eix_arch.exit_status.zero?
            arch = eix_arch.stdout.chomp
            ["~#{arch}"]
          else
            []
          end
        end
      end

      def target_default_directory
        "/etc/portage/package.accept_keywords"
      end
    end
  end 
end
