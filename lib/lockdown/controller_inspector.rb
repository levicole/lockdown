module Lockdown
  module ControllerInspector
    def self.included(base)
      if Lockdown.merb_app?
        base.send :include, Lockdown::ControllerInspector::Merb
      elsif Lockdown.rails_app?
        base.send :include, Lockdown::ControllerInspector::Rails
      end
    end

    module Core
      include Lockdown::Helper
      #
      # *syms is a splat of controller symbols,
      # e.g all_methods(:users, :authors, :books)
      #
      def all_methods(*syms)
        syms.collect{ |sym| paths_for(sym) }.flatten
      end
    
      #
      # controller name (sym) and a splat of methods to 
      # exclude from result
      #
      # All user methods except destroy:
      # e.g all_except_methods(:users, :destroy)
      #
      def all_except_methods(sym, *methods)
        paths_for(sym) - paths_for(sym, *methods) 
      end
    
      #
      # controller name (sym) and a splat of methods to 
      # to build the result
      # 
      # Only user methods index (list), show (good for readonly access):
      # e.g only_methods(:users, :index, :show)
      #
      def only_methods(sym, *methods)
        paths_for(sym, *methods)
      end

      #
      # all controllers, all actions
      #
      # This is admin access
      # 
      def all_controllers
        controllers = Lockdown::System.controller_classes
      
        controllers.collect do |controller|
          methods = available_actions(controller)
          paths_for(controller_name(controller), methods)
        end.flatten!
      end
    
      private 

      def paths_for(str_sym, *methods)
        str = str_sym.to_s if str_sym.is_a?(Symbol)
        if methods.empty?
          klass = Lockdown::System.fetch_controller_class(str)
          methods = available_actions(klass) 
        end
        methods.collect{|meth| ctr_path(str) + "/" + meth.to_s }
      end
    
      def ctr_path(str)
        str.gsub("__","\/")
      end

      #
      # Luckily both Rails and Merb have the controller_name method. This 
      # is here in case that changes.
      #
      def controller_name(klass)
        klass.controller_name
      end
    end #Core

    module Rails #:nodoc:
      include Lockdown::ControllerInspector::Core
      
      def available_actions(klass)
        klass.public_instance_methods - klass.hidden_actions
      end
    end # Rails

    module Merb #:nodoc:
      include Lockdown::ControllerInspector::Core
      
      def available_actions(klass)
        klass.callable_actions.keys
      end

    end # Merb
  end # ControllerInspector
end # Lockdown
