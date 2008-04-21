module Lockdown
  module Helper
    def syms_from_names(ary)
      rvalue = []
      ary.each{|ar| rvalue << symbolize(ar.name)}
      rvalue
    end

    def symbolize(str)
      str.downcase.gsub("admin ","admin__").gsub(" ","_").to_sym
    end

    def camelize(str)
      str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end
  end
end
