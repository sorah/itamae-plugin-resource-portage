require 'itamae-plugin-resource-portage/resources/base'

module ItamaePluginResourcePortage
  module Resources
    class PortageFileBase < Base
      define_attribute :action, default: :add
      define_attribute :target, type: String

      def value
        raise NotImplementedError
      end

      def item_list?
        !(value == true || value == false)
      end

      def pre_action
        case @current_action
        when :add
          attributes.value = value || (item_list? ? [] : false)
        when :remove
          attributes.value = item_list? ? [] : false
        end
      end

      def action_add(options)
        lines = current_content.lines.map(&:chomp)
        new_line = if item_list?
                     "#{atom} #{value.kind_of?(Array) ? value.join(' ') : value}"
                   else
                     atom.to_s
                   end
        modified = false

        if current_value
          if lines.grep(target_line_pattern).size > 1
            modified = true
            lines.reject! { |_| target_line_pattern === _ }
            lines << new_line
          else
            lines.map! do |_|
              if target_line_pattern === _
                if _.chomp != new_line
                  modified = true
                end
                new_line
              else
                _
              end
            end
          end
        else
          modified = true
          lines << new_line
        end

        if modified
          begin
            tempfile = Tempfile.new('portage_file')
            tempfile.puts lines.join(?\n)
          ensure
            tempfile.close
          end

          backend.send_file(tempfile.path, target)
          updated!
        end
      end

      def action_remove(options)
        lines = current_content.lines.map(&:chomp)

        new_lines = lines.reject { |_| target_line_pattern === _ }
        if lines.size != new_lines.size
          begin
            tempfile = Tempfile.new('portage_file')
            tempfile.puts new_lines.join(?\n)
          ensure
            tempfile.close
          end

          backend.send_file(tempfile.path, target)
          updated!
        end
      end

      def set_current_attributes
        current.value = current_value
      end

      def clear_current_attributes
        super
        @current_content = nil
        @current_value = nil
      end

      def current_content
        @current_content ||= target_exist? ? backend.receive_file(target) : "\n"
      end

      def current_value
        @current_value = begin
          lines = current_content.each_line.grep(target_line_pattern)

          # https://github.com/gentoo/portage/blob/1eb8e1e38c410a6b3792d005da7a75a87c811721/pym/portage/util/__init__.py
          if item_list?
            if lines.empty?
              nil
            else
              lines.flat_map { |_| _.chomp.split(/\s+/, 2)[1].split(/\s+/) }
            end
          else
            !lines.empty?
          end
        end
      end

      def target_default_directory
        raise NotImplementedError
      end

      def ensure_target_directory
        target
        if @target_dir_unexist
          run_command(['mkdir', '-p', target_default_directory])
        end
      end

      def target_line_pattern
        item_list? ? /^#{Regexp.escape(atom)}\s/ : /^#{Regexp.escape(atom)}$/
      end

      def target_exist?
        run_command(['test', '-e', target], error: false).exit_status == 0
      end

      def target
        @target ||= begin
          @target_dir_unexist = false
          if attributes.target && attributes.target.start_with?('/') # absolute path
            attributes.target
          else # relative
            stat = run_command(['stat', '-c', '%F' , target_default_directory], error: false)
            exist = stat.exit_status.zero?
            directory = exist && stat.stdout.chomp == 'directory'
            file = exist && stat.stdout.chomp == 'regular file'

            case
            when directory
              "#{target_default_directory}/#{attributes.target || 'itamae'}"
            when file
              target_default_directory
            else # enoent
              @target_dir_unexist = true
              "#{target_default_directory}/#{attributes.target || 'itamae'}"
            end
          end
        end
      end

    end
  end
end
