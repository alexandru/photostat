module Photostat

  class Config < Plugins::Base
    help_text "Global configuration utils"
    exposes :all, "Configures everything"

    def all
      Photostat::Plugins.all_in_order.each do |plugin|
        plugin.new.config
      end
    end
  end
end

    
