require 'itamae'

module ItamaePluginResourcePortage
  module Resources
    class Base < Itamae::Resource::Base
      module Attributes
        def self.included(klass)
          klass.instance_eval do
            define_attribute :name, type: String, default_name: true

            define_attribute :version, type: String
            define_attribute :slot, type: String
            define_attribute :atom, type: String
          end
        end
      end

      include Attributes

      def atom
        @atom ||= attributes.atom or begin
          case
          when attributes.version
            _, op, version, slot = attributes.version.match(/\A(!=|>=|>|=|<=|<|~)?(.+)(:.+)?\z/).to_a

            # XXX:
            if slot.nil? || slot.empty?
              if attributes.slot
                slot = ":#{attributes.slot}" 
              end
            else
              attributes.slot = slot[1..-1]
            end

            if op.nil? || op.empty?
              op = '='
            end
            @op = op

            "#{op}#{attributes.name}-#{version}#{slot}"
          when attributes.name
            @op = nil
            attributes.name
          else
            raise ArgumentError, "Can't determine atom"
          end
        end
      end

      def atom_op
        atom; @op
      end
    end
  end
end
