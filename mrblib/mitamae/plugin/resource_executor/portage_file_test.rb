module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortageFileTest < ::MItamae::ResourceExecutor::Base
        include MItamaePluginResourcePortage::ExecutorBases::PortageFile

        def value
          true
        end

        def self.target_default_directory=(x)
          @target_default_directory = x
        end

        def self.target_default_directory
          @target_default_directory
        end

        def target_default_directory
          self.class.target_default_directory or raise "no target_default_directory in #{self.class}"
        end
      end
    end
  end
end

