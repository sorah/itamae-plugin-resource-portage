require 'itamae/resource/base'
require 'itamae-plugin-resource-portage/resource_base'
require 'itamae-plugin-resource-portage/resources/portage_package'
require 'itamae-plugin-resource-portage/resources/portage_accept_keywords'
require 'itamae-plugin-resource-portage/resources/portage_mask'
require 'itamae-plugin-resource-portage/resources/portage_unmask'
require 'itamae-plugin-resource-portage/resources/portage_pin'
require 'itamae-plugin-resource-portage/resources/portage_use'

module ItamaePluginResourcePortage
  module Resources
    class Portage < Itamae::Resource::Base
      include ResourceBase::Attributes
      define_attribute :action, default: :install

      define_attribute :emerge_cmd, type: String, default: '/usr/bin/emerge'
      define_attribute :eix_cmd, type: String, default: '/usr/bin/eix'
      # define_attribute :eix_update_cmd, type: String, default: '/usr/bin/eix-update'

      define_attribute :package_use_file, type: String
      define_attribute :package_mask_file, type: String
      define_attribute :package_unmask_file, type: String
      define_attribute :package_accept_keywords_file, type: String

      define_attribute :unmask, type: [NilClass, TrueClass, FalseClass]
      define_attribute :pin, type: [TrueClass, FalseClass], default: false

      define_attribute :noreplace, type: [TrueClass, FalseClass], default: true
      define_attribute :oneshot, type: [TrueClass, FalseClass], default: false

      define_attribute :flags, type: [Array, String]
      define_attribute :keywords, type: [Array, String]

      def pre_action
        if attributes.pin && attributes.unmask
          raise ArgumentError, "pin and unmask can't be specified at once"
        end

        if attributes.pin && !attributes.version
          raise ArgumentError, "Should specify version when you want to pin"
        end
      end

      def action_install
        recipes = []
        recipes << recipe_use(:add) if attributes.flags
        recipes << recipe_accept_keywords(:add) if accept_keywords?
        case
        when attributes.pin
          recipes << recipe_pin(:pin)
        when unmask?
          recipes << recipe_unmask(:add)
        end
        recipes << recipe_package(:install)
        Itamae::RecipeChildren.new(recipes).run
      end

      def action_remove
        recipes = []
        recipes << recipe_use(:remove) if attributes.flags
        recipes << recipe_accept_keywords(:remove) if accept_keywords?
        case
        when attributes.pin
          recipes << recipe_pin(:unpin)
        when unmask?
          recipes << recipe_unmask(:remove)
        end
        recipes << recipe_package(:remove)
        Itamae::RecipeChildren.new(recipes).run
      end

      private

      def unmask?
        if attributes.unmask.nil?
          !!attributes.version
        else
          attributes.unmask
        end
      end

      def accept_keywords?
        if attributes.keywords.nil?
          !!attributes.version
        else
          !(attributes.keywords ||[] ).empty?
        end
      end

      def recipe_use(_action)
        _name, _version, _slot, _atom = self.attributes.name, self.attributes.version, self.attributes.slot, self.attributes.atom
        _target = self.attributes.package_use_file
        _flags = self.attributes.flags
        PortageUse.new(recipe, _name) do
          action _action
          target _target
          flags _flags
          version _version
          slot _slot
          atom _atom
        end
      end

      def recipe_accept_keywords(_action)
        _name, _version, _slot, _atom = self.attributes.name, self.attributes.version, self.attributes.slot, self.attributes.atom
        _target = self.attributes.package_accept_keywords_file
        _keywords = self.attributes.keywords
        PortageAcceptKeywords.new(recipe, _name) do
          action _action
          target _target
          keywords _keywords if _keywords
          version _version
          slot _slot
          atom _atom
        end
      end

      def recipe_pin(_action)
        _name, _version = self.attributes.name, self.attributes.version
        PortagePin.new(recipe, _name) do
          action _action
          version _version
        end
      end

      def recipe_unmask(_action)
        _name, _version, _slot, _atom = self.attributes.name, self.attributes.version, self.attributes.slot, self.attributes.atom
        _target = self.attributes.package_unmask_file
        PortageUnmask.new(recipe, _name) do
          action _action
          target _target
          version _version
          slot _slot
          atom _atom
        end
      end

      def recipe_package(_action)
        _name, _version, _slot, _atom = self.attributes.name, self.attributes.version, self.attributes.slot, self.attributes.atom
        _emerge_cmd, _eix_cmd = self.attributes.emerge_cmd, self.attributes.eix_cmd
        _noreplace, _oneshot = self.attributes.noreplace, self.attributes.oneshot
        PortagePackage.new(recipe, _name) do
          action _action
          version _version if _version
          slot _slot
          atom _atom

          emerge_cmd _emerge_cmd
          eix_cmd _eix_cmd

          noreplace _noreplace
          oneshot _oneshot
        end
      end
    end
  end
end
