module ::MItamae
  module Plugin
    module Resource
      class PortageAcceptKeywords < ::MItamae::Resource::Base
        include MItamaePluginResourcePortage::ResourceBases::Portage
        include MItamaePluginResourcePortage::ResourceBases::PortageFile

        define_attribute :keywords, type: [String, Array, NilClass]
      end
    end
  end
end
