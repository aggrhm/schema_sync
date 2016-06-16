module SchemaSync

  module Model

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def field(name, opts)
        SchemaSync.register_model(self)
        schema_type = opts[:schema_type] || SchemaSync.schema_type_for(opts[:type])
        if schema_type == :jsonb && opts[:default].is_a?(Hash)
          opts[:default] = opts[:default].to_json
        end
        schema_fields[name] = opts.merge(name: name, table_name: self.table_name, schema_type: schema_type)
      end

      def timestamps!(opts={})
        field :created_at, type: Time
        field :updated_at, type: Time
      end

      def schema_fields
        @schema_fields ||= {}
      end

      def schema_enhancements
        @schema_enhancements ||= []
      end

      def timestamp_columns_exist?
        return false if !self.table_exists?
        cns = self.column_names
        cns.include?("created_at") && cns.include?("updated_at")
      end

    end

  end

end
