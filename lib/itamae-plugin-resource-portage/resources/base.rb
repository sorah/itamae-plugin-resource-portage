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
          if attributes.version
            _, op, version, slot = attributes.version.match(/\A(!=|>|>=|=|<=|<|~)?(.+)(:.+)?\z/).to_a

            slot = attributes.slot if slot.nil? || slot.empty?
            attributes.slot = slot
            attributes.op = op unless slot.nil? || slot.empty?

            "#{op}#{attributes.name}-#{version}#{slot}"
          else
            attributes.name
          end
        end
      end
    end
  end
end
