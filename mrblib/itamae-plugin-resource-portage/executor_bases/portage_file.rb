module ::MItamaePluginResourcePortage
  module ExecutorBases
    module PortageFile
      include MItamaePluginResourcePortage::ExecutorBases::Portage

      def value
        raise NotImplementedError
      end

      def item_list?
        !(value == true || value == false)
      end

      def apply
        if desired.added
          action_add
        else
          action_remove
        end
      end

      def set_current_attributes(current, action)
        current.value = current_value
        current.added = !!current_value && (item_list? ? value.all? { |_| current_value.include?(_) } : value == current_value)
      end

      def set_desired_attributes(desired, action)
        process_desired_atom(desired)

        @desired = desired # #value method requires this to be set

        case action
        when :add
          desired.added = true
          desired.value = value || (item_list? ? [] : false)
        when :remove
          desired.added = false
          desired.value = item_list? ? [] : false
        end
      end

      def action_add
        lines = current_content.lines.map(&:chomp)
        new_line = if item_list?
                     "#{desired.atom} #{value.kind_of?(Array) ? value.join(' ') : value}"
                   else
                     desired.atom.to_s
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
          send_file(lines.join(?\n))
          updated!
        end
      end

      def action_remove
        lines = current_content.lines.map(&:chomp)

        new_lines = lines.reject { |_| target_line_pattern === _ }
        if lines.size != new_lines.size
          send_file(new_lines.join(?\n))
          updated!
        end
      end

      def send_file(content)
        ensure_target_directory

        File.open(target, 'w') do |io|
          io.puts content
        end
      end

      def current_content
        @current_content ||= target_exist? ? File.read(target) : "\n"
      end

      def current_value
        @current_value ||= begin
          lines = current_content.lines.grep(target_line_pattern)
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
        item_list? ? /^#{Regexp.escape(desired.atom)}\s/ : /^#{Regexp.escape(desired.atom)}$/
      end

      def target_exist?
        File.exist?(target)
      end

      def target
        @target ||= begin
          @target_dir_unexist = false
          if attributes.target && attributes.target.start_with?('/') # absolute path
            attributes.target
          else # relative
            case
            when File.directory?(target_default_directory)
              "#{target_default_directory}/#{attributes.target || 'itamae'}"
            when File.exist?(target_default_directory)
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
