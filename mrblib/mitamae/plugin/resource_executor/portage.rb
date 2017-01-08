module ::MItamae
  module Plugin
    module ResourceExecutor
      class Portage < ::MItamae::ResourceExecutor::Base
        def set_current_attributes(current, action)
          # no action
        end

        def set_desired_attributes(desired, action)
          case action
          when :install, :update
            desired.installed = true
          when :remove
            desired.installed = false
          else
            raise ArgumentError, "Portage doesn't know #{action} method"
          end
        end

        def pre_action
          if desired.pin && desired.unmask
            raise ArgumentError, "pin and unmask can't be specified at once"
          end

          if desired.pin && !desired.version
            raise ArgumentError, "Should specify version when you want to pin"
          end

          if @runner.dry_run?
            apply
          end
        end

        def apply
          if desired.installed
            action_install
          else
            action_remove
          end
        end

        def action_install
          ::MItamae::RecipeExecutor.new(@runner).execute(install_children)
        end

        def action_remove
          ::MItamae::RecipeExecutor.new(@runner).execute(remove_children)
        end

        def unmask?
          if desired.unmask.nil?
            !!desired.version
          else
            desired.unmask
          end
        end

        def accept_keywords?
          if desired.keywords.nil?
            !!desired.version
          else
            !(desired.keywords ||[] ).empty?
          end
        end

        private

        def install_children
          recipes = []
          recipes << recipe_use(:add) if desired.flags
          recipes << recipe_accept_keywords(:add) if accept_keywords?
          case
          when desired.pin
            recipes << recipe_pin(:pin)
          when unmask?
            recipes << recipe_unmask(:add)
          end
          recipes << recipe_package(:install)
          recipes
        end

        def remove_children
          recipes = []
          recipes << recipe_use(:remove) if desired.flags
          recipes << recipe_accept_keywords(:remove) if accept_keywords?
          case
          when desired.pin
            recipes << recipe_pin(:unpin)
          when unmask?
            recipes << recipe_unmask(:remove)
          end
          recipes << recipe_package(:remove)
          recipes
        end

        def recipe_use(_action)
          _name, _version, _slot, _atom = desired.name, desired.version, desired.slot, desired.atom
          _target = desired.package_use_file
          _flags = desired.flags

          ::MItamae::Plugin::Resource::PortageUse.new(_name, @resource.recipe, {}) do
            name _name
            action _action
            target _target
            flags _flags
            version _version
            slot _slot
            atom _atom
          end
        end

        def recipe_accept_keywords(_action)
          _name, _version, _slot, _atom = desired.name, desired.version, desired.slot, desired.atom
          _target = desired.package_accept_keywords_file
          _keywords = desired.keywords

          ::MItamae::Plugin::Resource::PortageAcceptKeywords.new(_name, @resource.recipe, {}) do
            name _name
            action _action
            target _target
            keywords _keywords if _keywords
            version _version
            slot _slot
            atom _atom
          end
        end

        def recipe_pin(_action)
          _name, _version = desired.name, desired.version

          ::MItamae::Plugin::Resource::PortagePin.new(_name, @resource.recipe, {}) do
            name _name
            action _action
            version _version
          end
        end

        def recipe_unmask(_action)
          _name, _version, _slot, _atom = desired.name, desired.version, desired.slot, desired.atom
          _target = desired.package_unmask_file

          ::MItamae::Plugin::Resource::PortageUnmask.new(_name, @resource.recipe, {}) do
            name _name
            action _action
            target _target
            version _version
            slot _slot
            atom _atom
          end
        end

        def recipe_package(_action)
          _name, _version, _slot, _atom = desired.name, desired.version, desired.slot, desired.atom
          _emerge_cmd, _eix_cmd = desired.emerge_cmd, desired.eix_cmd
          _noreplace, _oneshot = desired.noreplace, desired.oneshot

          ::MItamae::Plugin::Resource::PortagePackage.new(_name, @resource.recipe, {}) do
            name _name
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
end
