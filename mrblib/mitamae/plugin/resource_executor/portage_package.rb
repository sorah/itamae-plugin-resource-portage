module ::MItamae
  module Plugin
    module ResourceExecutor
      class PortagePackage < ::MItamae::ResourceExecutor::Base
        class EixNotFound < StandardError; end

        include MItamaePluginResourcePortage::ExecutorBases::Portage

        def set_desired_attributes(desired, action)
          process_desired_atom(desired)
          case action
          when :install
            desired.installed = true
          when :update
            desired.installed = true
            desired.upgrading = true
          when :remove
            desired.installed = false
          else
            raise ArgumentError, "PortagePackage resource doesn't know #{action} action"
          end
        end

        def set_current_attributes(current, action)
          @desired = Hashie::Mash.new(desired) # FIXME:
          if eix_determinable?
            begin
              result = eix(attributes.name).find {|_| _[:name] == attributes.name }
            rescue EixNotFound => e
              if @runner.dry_run?
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

            if !desired.version
              if action == :update
                desired.version = if desired.slot
                                       result[:best_slot_versions][desired.slot]
                                     else
                                       result[:best_version]
                                     end
              else
                desired.version = current.version
              end
              desired.atom = nil
              process_desired_atom(desired)
            end
          else
            update = action == :update ? %w(-u) : []
            noreplace = attributes.noreplace ? %w(--noreplace) : []
            pvn = run_command([attributes.emerge_cmd, '--nospinner', '--color=n', '-pv', *noreplace, *update, desired.atom], error: false)

            current.installed = /Total: 0 packages/ === pvn.stdout
            if current.installed
              current.version = attributes.version
            else
              current.version = nil
            end
          end
        ensure
          @desired.freeze unless @desired.frozen?
        end

        def pre_action
          @current = Hashie::Mash.new(current) # FIXME:
          if !desired.noreplace
            current.installed = false
          end
        ensure
          @current.freeze unless @current.frozen?
        end

        def apply
          if desired.installed
            action_install
          else
            action_remove
          end
        end

        def action_install
          case
          when !desired.noreplace
            emerge!
          when !current.installed && desired.installed
            emerge!
          when current.installed && (desired.version.nil? || (desired.version != current.version))
            emerge!
          end
        end

        def action_remove
          case
          when current.installed
            unmerge!
          end
        end

        def emerge!
          update = desired.upgrading ? %w(-u) : []
          noreplace = desired.noreplace ? %w(--noreplace) : []
          run_command([attributes.emerge_cmd, '--nospinner', '--color=n', '-v', *update, *noreplace, desired.atom])
          updated!
        end

        def unmerge!
          run_command([attributes.emerge_cmd, '--nospinner', '--color=n', '--rage-clean', '-v', desired.atom])
          updated!
        end

        private

        def eix_determinable?
          !desired.atom_given && (!desired.version || desired.op == '=')
        end

        def eix(*options)
          result = run_command(['env', "MYVERSION=<version>:<slot>{!last} {}", desired.eix_cmd, '--nocolor', '--pure-packages', '--format', "<category>/<name>|<installedversions:MYVERSION>|<bestslotversions:MYVERSION>|<bestversion:MYVERSION>\\n", *options], error: false)

          unless result.exit_status == 0
            errmsg_regex = /#{Regexp.escape(desired.eix_cmd)}: No such file or directory$/
            if result.stdout.match(errmsg_regex) || result.stderr.match(errmsg_regex)
              raise EixNotFound, "eix should be set up to use PortagePackage resource"
            end
            return []
          end

          result.stdout.lines.map do |line|
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
end

