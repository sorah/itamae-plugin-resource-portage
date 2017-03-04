require 'itamae'
require 'itamae-plugin-resource-portage/resources/portage_mask'
require 'itamae-plugin-resource-portage/resources/portage_unmask'

module ItamaePluginResourcePortage
  module Resources
    class PortagePin < Itamae::Resource::Base
      define_attribute :name, type: String, default_name: true
      define_attribute :action, default: :pin
      define_attribute :version, type: String, required: true

      def action_pin
        Itamae::RecipeChildren.new([mask(:add), unmask(:add)]).run
      end

      def action_unpin
        Itamae::RecipeChildren.new([mask(:remove), unmask(:remove)]).run
      end

      private

      def mask(_action)
        PortageMask.new(recipe, self.attributes.name) do
          action _action
        end
      end

      def unmask(_action)
        _version = self.attributes.version
        unless /^[0-9]/ === _action
          raise ArgumentError, "PortagePin version should not include operators but #{_version.inspect}"
        end

        PortageUnmask.new(recipe, self.attributes.name) do
          action _action
          version "=#{_version}"
        end
      end
    end
  end 
end
