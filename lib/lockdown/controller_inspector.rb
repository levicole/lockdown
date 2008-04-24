require File.join(File.dirname(__FILE__), "helper") unless Lockdown.const_defined?("Helper")

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
        controllers = find_all_controller_classes
      
        controllers.collect do |controller|
          methods = available_actions(controller)
          paths_for(controller_name(controller), methods)
        end.flatten!
      end
    
      private 

      def paths_for(sym_str, *methods)
        str = sym_str.to_s if sym_str.is_a?(Symbol)
        if methods.empty?
          klass = get_controller_class(str)
          methods = available_actions(klass) 
        end
        methods.collect{|meth| ctr_path(str) + "/" + meth.to_s }
      end
    
      def get_controller_class(str)
        load_controller(str)
        lockdown_const_get(str)
      end

      def find_all_controller_classes
        load_all_controllers
        return ObjectSpace.controller_classes
      end

      def ObjectSpace.controller_classes
        subclasses = []
        self.each_object(Class) do |klass|
          subclasses << klass if klass.ancestors.include?(Lockdown.controller_parent)
        end
        subclasses
      end
      
      def load_controller(str)
        unless lockdown_const_defined?("Application")
          require(Lockdown.project_root + "/app/controllers/application.rb")
        end
        
        unless lockdown_const_defined?(kontroller_class_name(str))
          require(Lockdown.project_root + "/app/controllers/#{kontroller_file_name(str)}")
        end
      end

      def load_all_controllers
        Dir["#{Lockdown.project_root}/app/controllers/**/*.rb"].sort.each do |c|
         require(c) unless c == "application.rb"
        end
      end
      
      def lockdown_const_defined?(str)
        if str.include?("__")
          # this is a namespaced controller.  need to apply const_defined_to the namespace
          parts = str.split("__")
          eval("#{camelize(parts[0])}.const_defined?(\"#{kontroller_class_name(parts[1])}\")") 
        else
          const_defined?(camelize(str))
        end
      end

      def lockdown_const_get(str)
        if str.include?("__")
          # this is a namespaced controller.  need to apply const_get the namespace
          parts = str.split("__")
          eval("#{camelize(parts[0])}.const_get(\"#{kontroller_class_name(parts[1])}\")") 
        else
          const_get(kontroller_class_name(str))
        end
      end

      def ctr_path(str)
        str.gsub("__","\/")
      end

      #
      # Convert the str parameter (originally the symbol) to the 
      # class name.
      #
      # For a controller defined as :users in access.rb, the str
      # parameter here would be "users". The result of this method
      # would be "/users"
      #
      # For a namespaced controller:
      # In access.rb it would be defined as :admin__users.
      # The str paramter would be "admin__users".
      # The result would be "/admin/users".
      #
      def controller_file_name(str)
        if str.include?("__")
          str.split("__").join("/")
        else
          str
        end
      end

      #
      # Convert the str parameter (originally the symbol) to the 
      # class name.
      #
      # For a controller defined as :users in access.rb, the str
      # parameter here would be "users". The result of this method
      # would be "Users"
      #
      def controller_class_name(str)
        if str.include?("__")
          str.split("__").collect{|p| camelize(p)}.join("::")
        else
          camelize(str)
        end
      end

      #
      # The reverse of controller_class_name.  Convert the controllers
      # class name to the string version of the symbols used in acces.rb.
      #
      # For a controller defined as :users in access.rb, the klass 
      # parameter here would be Users (the class). The result of this method
      # would be "users", the string version of :users.
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
      
      def kontroller_class_name(str)
        "#{controller_class_name(str)}Controller"
      end

      def kontroller_file_name(str)
       "#{controller_file_name(str)}_controller.rb"
      end

      def available_actions(klass)
        klass.public_instance_methods - klass.hidden_actions
      end
    end # Rails

    module Merb #:nodoc:
      include Lockdown::ControllerInspector::Core
      
      def kontroller_class_name(str)
        controller_class_name(str)
      end

      def kontroller_file_name(str)
       controller_file_name(str) + ".rb"
      end

      def available_actions(klass)
        klass.callable_actions.keys
      end

    end # Merb
  end # ControllerInspector
end # Lockdown
