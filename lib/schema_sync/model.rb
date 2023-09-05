module SchemaSync

  module Model

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def has_table_options(opts)
        schema_table_options.merge!(opts)
      end

      def field(name, opts)
        SchemaSync.register_model(self)
        schema_type = opts[:schema_type] || SchemaSync.schema_type_for(opts[:type])
        schema_fields[name] = opts.merge(name: name, table_name: self.table_name, schema_type: schema_type)
        if opts[:index].present?
          iopts = opts[:index].is_a?(Hash) ? opts[:index] : {}
          index(name.to_sym, iopts)
        end
        if opts[:foreign_key_to].present?
          opts[:foreign_key] = {to_table: opts[:foreign_key_to]}
        end
        if opts[:foreign_key].present?
          foreign_key(name.to_sym, opts[:foreign_key])
        end
        if opts[:scope] == true
          scope "with_#{name}", lambda {|val|
            where(name => val)
          }
        end
      end

      def index(fields, opts={})
        fields = [fields] if !fields.is_a?(Array)
        schema_indexes[fields] = opts.merge(table_name: self.table_name, fields: fields, columns: fields.collect(&:to_s))
      end

      def foreign_key(field, opts)
        schema_foreign_keys[field] = opts.merge(table_name: self.table_name, column: field)
      end

      def timestamps!(opts={})
        field :created_at, opts.merge(type: Time)
        field :updated_at, opts.merge(type: Time)
      end

      def schema_table_options
        @schema_table_options ||= {}
      end

      def schema_fields
        @schema_fields ||= {}
      end

      def schema_indexes
        @schema_indexes ||= {}
      end

      def schema_foreign_keys
        @schema_foreign_keys ||= {}
      end

      def schema_enhancements
        @schema_enhancements ||= []
      end

      def timestamp_columns_exist?
        return false if !self.table_exists?
        cns = self.column_names
        cns.include?("created_at") && cns.include?("updated_at")
      end

    end   ## END CLASS METHODS

    def fields_to_api(opts={})
      ret = {}
      self.class.schema_fields.values.each do |field|
        fname = field[:name]
        aopts = field[:to_api]
        next if aopts == false
        val = self.send(fname)
        if aopts.is_a?(Symbol)
          val = val.send(aopts) if !val.nil?
        elsif aopts.respond_to?(:call)
          val = self.instance_exec(val, &aopts)
        end
        ret[fname] = val
      end
      return ret
    end

  end

end
