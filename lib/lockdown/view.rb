module Lockdown
  module View
    module Core
      def links(*lis)
        rvalue = []
        lis.each{|link| rvalue << link if link.length > 0 }
        rvalue.join(" | ")
      end
    end # Core

    module Merb
      include Lockdown::View::Core
      def self.included(base)
        base.class_eval do
           alias :merb_link_to  :link_to
        end
      end

      def link_to(name, url = '', options = {})
        if authorized? url
          return merb_link_to(name, url, options)
        end
        return ""
      end

			def link_to_or_show(name, url = '', options = {})
				lnk = link_to(name, options, html_options)
				lnk.length == 0  ? name : lnk
      end
    end # Merb

    module Rails
      include Lockdown::View::Core
      def self.included(base)
        base.class_eval do
           alias :rails_link_to  :link_to
           alias :rails_button_to  :button_to
        end
      end
    
      def link_to(name, options = {}, html_options = nil)
        url = lock_down_url(options, html_options)
        if authorized? url
          return rails_link_to(name,options,html_options)
        end
        return ""
      end

			def link_to_or_show(name, options = {}, html_options = nil)
				lnk = link_to(name, options, html_options)
				lnk.length == 0 ? name : lnk
      end

    
      def button_to(name, options = {}, html_options = nil)
        url = lock_down_url(options, html_options)
        if authorized? url
          return rails_button_to(name,options,html_options)
        end
        return ""
      end
      
    
      private
        def lock_down_url(options, html_options = {})
          return options unless options.respond_to?(:new_record?)
          p = polymorphic_path(options)
          if html_options.is_a?(Hash) && html_options[:method] == :delete
            p += "/destroy"
          elsif p.split("/").last.to_i > 0
            p += "/show"
          end
          return p
        end
    end # Rails
  end # View
end # Lockdown

if Object.const_defined?("Merb") && Merb.const_defined?("AssetsMixin")
  Merb::AssetsMixin.send :include, Lockdown::View::Merb
elsif Object.const_defined?("ActionView")
  ActionView::Helpers::UrlHelper.send :include, Lockdown::View::Rails
else
  raise NotImplementedError, "Application helper unknown to Lockdown."
end

