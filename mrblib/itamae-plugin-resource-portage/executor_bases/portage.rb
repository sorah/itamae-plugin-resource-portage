module ::MItamaePluginResourcePortage
  module ExecutorBases
    module Portage
      def process_desired_atom(desired)
        desired.atom_given = false
        case
        when desired.atom
          desired.atom_given = true
        when desired.version
          _, op, version, slot = desired.version.match(/\A(!=|>=|>|=|<=|<|~)?(.+)(:.+)?\z/).to_a

          # XXX:
          if slot.nil? || slot.empty?
            if desired.slot
              slot = ":#{desired.slot}" 
            end
          else
            desired.slot = slot[1..-1]
          end

          if op.nil? || op.empty?
            op = '='
          end

          desired.op = op
          desired.atom = "#{op}#{desired.name}-#{version}#{slot}"
        when desired.name
          desired.op = '='
          desired.atom = desired.name
        else
          raise ArgumentError, "Can't determine atom"
        end
      end
    end
  end
end
