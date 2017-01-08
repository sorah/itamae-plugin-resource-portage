module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortageUnmask < ::MItamae::ResourceExecutor::Base
        include MItamaePluginResourcePortage::ExecutorBases::PortageFile

        def value
          true
        end

        def target_default_directory
          "/etc/portage/package.unmask"
        end
      end
    end
  end
end

