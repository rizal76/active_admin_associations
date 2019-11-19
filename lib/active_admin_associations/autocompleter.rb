module ActiveAdminAssociations
  module Autocompleter
    extend ActiveSupport::Concern

    module ClassMethods
      def autocomplete(attribute, options = {})
        class_attribute :autocomplete_attribute
        class_attribute :autocomplete_options

        self.autocomplete_attribute = attribute
        self.autocomplete_options = options

        extend AutocompleteMethods
      end
    end

    module AutocompleteMethods
      def autocomplete_results(query)
        results = where("#{table_name}.#{autocomplete_attribute} LIKE ?", "#{query.downcase}%").
          order("#{table_name}.#{autocomplete_attribute} ASC")
        results.map do |record|
          _autocomplete_format_result(record)
        end
      end
      
      private
      
      def _autocomplete_format_result(record)
        if configured_autocomplete_result_formatter?
          activeadmin_associations_config.autocomplete_result_formatter.call(record,
            autocomplete_attribute, autocomplete_options)
        else
          label = _format_autocomplete_label(record)
          {"label"  => label, # This plays nice with both jQuery UI autocomplete and jquery.tokeninput
            "value" => record.send(autocomplete_attribute), 
            "id"    => record.id}
        end
      end
      
      def _format_autocomplete_label(record)
        if autocomplete_options[:format_label].present?
          if autocomplete_options[:format_label].is_a?(Symbol)
            return record.send(autocomplete_options[:format_label])
          elsif autocomplete_options[:format_label].respond_to?(:call)
            return autocomplete_options[:format_label].call(record)
          end
        end
        record.send(autocomplete_attribute)
      end
      
      def configured_autocomplete_result_formatter?
        activeadmin_associations_config.autocomplete_result_formatter.present? &&
          activeadmin_associations_config.autocomplete_result_formatter.respond_to?(:call)
      end
      
      def activeadmin_associations_config
        Rails.application.config.activeadmin_associations
      end
    end
  end
end
