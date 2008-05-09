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
        base.send :alias_method, :link_to_open,  :link_to
        base.send :alias_method, :link_to,  :link_to_secured
      end

      def link_to_secured(name, url = '', options = {})
        if authorized? url
          return link_to_open(name, url, options)
        end
        return ""
      end

      def link_to_or_show(name, url = '', options = {})
        lnk = link_to(name, url , options)
        lnk.length == 0  ? name : lnk
      end
    end # Merb

    module Rails
      include Lockdown::View::Core
      def self.included(base)
        base.send :alias_method, :link_to_open,  :link_to
        base.send :alias_method, :link_to,  :link_to_secured

        base.send :alias_method, :button_to_open,  :button_to
        base.send :alias_method, :button_to,  :button_to_secured
      end
    
      def link_to_secured(name, options = {}, html_options = nil)
        # Don't want to go through the url_for twice
        url = url_for(options)
        if authorized? test_path(url, html_options)
          return link_to_open(name, url, html_options)
        end
        return ""
      end

      def link_to_or_show(name, options = {}, html_options = nil)
        lnk = link_to(name, options, html_options)
        lnk.length == 0 ? name : lnk
      end
    
      def button_to_secured(name, options = {}, html_options = nil)
        url = url_for(options)
        if authorized? test_path(url, html_options)
          return button_to_open(name, url, html_options)
        end
        return ""
      end
    
      private

      def test_path(url, html_options)
        if html_options.is_a?(Hash) && html_options[:method] == :delete
          url += "/destroy"
        elsif url.split("/").last =~ /\A\d+\z/
          url += "/show"
        end
        url 
      end
    end # Rails
  end # View
end # Lockdown

if Object.const_defined?("Merb") && Merb.const_defined?("AssetsMixin")
  Merb::AssetsMixin.send :include, Lockdown::View::Merb
elsif Object.const_defined?("ActionView")
  ActionView::Base.send :include, Lockdown::View::Rails
else
  raise NotImplementedError, "Application helper unknown to Lockdown."
end

