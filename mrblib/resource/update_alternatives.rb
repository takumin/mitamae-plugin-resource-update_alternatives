module ::MItamae
  module Plugin
    module Resource
      class UpdateAlternatives < ::MItamae::Resource::Base
        define_attribute :action, default: :install
        define_attribute :name, type: String, default_name: true
        define_attribute :path, type: String, default: nil
        define_attribute :link, type: String, default: nil
        define_attribute :priority, type: Integer, default: nil
        define_attribute :auto, type: [TrueClass, FalseClass], default: true

        self.available_actions = [:install, :remove]
      end
    end
  end
end
