module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortagePin < ::MItamae::ResourceExecutor::Base
        def set_current_attributes(current, action)
          # no action
        end

        def set_desired_attributes(desired, action)
          case action
          when :pin
            desired.pinned = true
          when :unpin
            desired.pinned = false
          else
            raise ArgumentError, "PortagePin doesn't know #{action} method"
          end
        end

        def apply
          if desired.pinned
            action_pin
          else
            action_unpin
          end
        end

        def action_pin
          ::MItamae::RecipeExecutor.new(@runner).execute([mask(:add), unmask(:add)])
        end

        def action_unpin
          ::MItamae::RecipeExecutor.new(@runner).execute([mask(:remove), unmask(:remove)])
        end

        private

        def action_name
          desired.pinned ? "pin" : "unpin"
        end

        def mask(_action)
          _target = desired.mask_target
          _name = desired.name
          ::MItamae::Plugin::Resource::PortageMask.new("#{action_name}: #{desired.name}", @resource.recipe, {}) do
            name _name
            action _action
            target _target if _target
          end
        end

        def unmask(_action)
          _version = desired.version
          _target = desired.unmask_target
          _name = desired.name
          ::MItamae::Plugin::Resource::PortageUnmask.new("#{action_name}: #{desired.name}", @resource.recipe, {}) do
            name _name
            action _action
            target _target if _target
            version "=#{_version}"
          end
        end
      end
    end
  end
end
