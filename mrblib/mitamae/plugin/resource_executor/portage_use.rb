module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortageUse < ::MItamae::ResourceExecutor::Base
        include MItamaePluginResourcePortage::ExecutorBases::PortageFile

        def value
          desired.flags
        end

        def target_default_directory
          "/etc/portage/package.use"
        end
      end
    end
  end
end
