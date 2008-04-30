module Lockdown
  module Model
    def self.included(base)
      base.send :include, Lockdown::Model::InstanceMethods
    end

    module InstanceMethods
      def self.included(base)
        base.class_eval do
          alias :create_without_stamps  :create
          alias :update_without_stamps  :update
        end
      end

      def current_profile_id
        Thread.current[:profile_id]
      end


      def create_with_stamps
        profile_id = current_profile_id || Profile::SYSTEM
        self[:created_by] = profile_id if self.respond_to?(:created_by) 
        self[:updated_by] = profile_id if self.respond_to?(:updated_by) 
        create_without_stamps
      end
      alias :create  :create_with_stamps
                  
      def update_with_stamps
        profile_id = current_profile_id || Profile::SYSTEM
        self[:updated_by] = profile_id if self.respond_to?(:updated_by)
        update_without_stamps
      end
      alias :update  :update_with_stamps
    end # InstanceMethods
  end # Model
end # Lockdown

Lockdown.orm_parent.send :include, Lockdown::Model
