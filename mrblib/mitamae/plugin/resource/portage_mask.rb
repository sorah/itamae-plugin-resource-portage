module ::MItamae
  module Plugin
    module Resource
      class PortageMask < ::MItamae::Resource::Base
        include MItamaePluginResourcePortage::ResourceBases::Portage
        include MItamaePluginResourcePortage::ResourceBases::PortageFile
      end
    end
  end
end
