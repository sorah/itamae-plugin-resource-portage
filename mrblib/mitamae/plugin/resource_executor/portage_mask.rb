module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortageMask < ::MItamae::ResourceExecutor::Base
        include MItamaePluginResourcePortage::ExecutorBases::PortageFile

        def value
          true
        end

        def target_default_directory
          "/etc/portage/package.mask"
        end
      end
    end
  end
end

