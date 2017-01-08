module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortageAcceptKeywords < ::MItamae::ResourceExecutor::Base
        include MItamaePluginResourcePortage::ExecutorBases::PortageFile

        def value
          desired.keywords || default_accept_keywords
        end

        def default_accept_keywords
          @default_accept_keywords ||= begin
            eix_arch = run_command(%w(eix --print ARCH), error: false)
            if eix_arch.exit_status == 0
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
end

