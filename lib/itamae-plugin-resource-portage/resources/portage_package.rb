require 'itamae-plugin-resource-portage/resource_base'

module ItamaePluginResourcePortage
  module Resources
    class PortagePackage < ResourceBase
      class EixNotFound < StandardError; end

      define_attribute :action, default: :install
      define_attribute :emerge_cmd, type: String, default: '/usr/bin/emerge'
      define_attribute :eix_cmd, type: String, default: '/usr/bin/eix'
      # define_attribute :eix_update_cmd, type: String, default: '/usr/bin/eix-update'

      define_attribute :noreplace, type: [TrueClass, FalseClass], default: true
      define_attribute :oneshot, type: [TrueClass, FalseClass], default: false

      def pre_action
        atom
        case @current_action
        when :unmerge, :remove
          attributes.installed = false
        when :update, :install
          attributes.installed = true
        end
      end

      def set_current_attributes
        check_installation
      end

      def action_install
        case
        when !attributes.noreplace
          emerge!
        when !current.installed && attributes.installed
          emerge!
        when current.installed && (attributes.version.nil? || (attributes.version != current.version))
          emerge!
        end
      end
      alias action_update action_install

      def action_unmerge
        case
        when current.installed
          unmerge!
        end
      end
      alias action_remove action_unmerge

      def unmerge!
        run_command([attributes.emerge_cmd, '--nospinner', '--color=n', '--rage-clean', '-v', atom])
        updated!
      end

      def emerge!
        update = @current_action == :update ? %w(-u) : []
        noreplace = attributes.noreplace ? %w(--noreplace) : []
        run_command([attributes.emerge_cmd, '--nospinner', '--color=n', '-v', '--quiet-fail', *update, *noreplace, atom])
        updated!
      end

      private

      def eix_determinable?
        !attributes.atom && (!attributes.version || atom_op == '=')
      end

      def check_installation
        if eix_determinable?
          begin
            result = eix(attributes.name).find {|_| _[:name] == attributes.name }
          rescue EixNotFound => e
            if recipe.runner.dry_run?
              current.installed = false
              current.version = nil
              return
            else
              raise 
            end
          end

          if !result
            raise ArgumentError, "package #{attributes.name} not found on eix"
          end

          installed_version = if attributes.slot
                                result[:installed_versions][attributes.slot]
                              else
                                result[:installed_version]
                              end
          if installed_version
            current.installed = true
            current.version = result[:installed_version]
          else
            current.installed = false
            current.version = nil
          end

          if !attributes.version
            if @current_action == :update
              attributes.version = if attributes.slot
                                     result[:best_slot_versions][attributes.slot]
                                   else
                                     result[:best_version]
                                   end
            else
              attributes.version = current.version
            end

            @atom = nil; atom
          end
        else
          update = @current_action == :update ? %w(-u) : []
          noreplace = attributes.noreplace ? %w(--noreplace) : []
          pvn = run_command([attributes.emerge_cmd, '--nospinner', '--color=n', '-pv', *noreplace, *update, atom], error: false)

          current.installed = /Total: 0 packages/ === pvn.stdout
          if current.installed
            current.version = attributes.version
          else
            current.version = nil
          end
        end
      end

      def eix(*options)
        result = run_command(['env', "MYVERSION=<version>:<slot>{!last} {}", attributes.eix_cmd, '--nocolor', '--pure-packages', '--format', "<category>/<name>|<installedversions:MYVERSION>|<bestslotversions:MYVERSION>|<bestversion:MYVERSION>\\n", *options], error: false)

        unless result.exit_status.zero?
          errmsg_regex = /#{Regexp.escape(attributes.eix_cmd)}: No such file or directory$/
          if result.stdout.match(errmsg_regex) || result.stderr.match(errmsg_regex)
            raise EixNotFound
          end
          return []
        end

        result.stdout.each_line.map do |line|
          name, installedversions, bestslotversions, bestversion = line.chomp.split(?|, 4)

          best_version, best_version_slot = bestversion.split(?:,2)

          installedversion = installedversions.split(/ /).last
          if installedversion
            installed_version, installed_version_slot = installedversion.split(?:,2)
          end

          {
            name: name,
            installed_versions: Hash[installedversions.split(/ /).map{ |_| _.split(?:, 2) }.group_by(&:last).map { |k,v| [k, v.map(&:first).last] }],
            best_slot_versions: Hash[bestslotversions.split(/ /).map{ |_| _.split(?:, 2) }.group_by(&:last).map { |k,v| [k, v.map(&:first).last] }],
            best_version: best_version,
            best_version_slot: best_version_slot,
            installed_version: installed_version,
            installed_version_slot: installed_version_slot,
          }
        end
      end
    end
  end 
end
