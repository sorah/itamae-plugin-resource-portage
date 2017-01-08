module ::MItamae
  module Plugin
    module Resource
      class PortageUse < ::MItamae::Resource::Base
        include MItamaePluginResourcePortage::ResourceBases::Portage
        include MItamaePluginResourcePortage::ResourceBases::PortageFile

        define_attribute :flags, type: Array
      end
    end
  end
end
