module JSONAPI
  class Relationship
    attr_reader :acts_as_set, :foreign_key, :options, :name,
                :class_name, :polymorphic, :absolute, :always_include_linkage_data,
                :parent_resource, :eager_load_on_include

    def initialize(name, options = {})
      @name = name.to_s
      @options = options
      @acts_as_set = options.fetch(:acts_as_set, false) == true
      @foreign_key = options[:foreign_key] ? options[:foreign_key].to_sym : nil
      @parent_resource = options[:parent_resource]
      @relation_name = options.fetch(:relation_name, @name)
      @polymorphic = options.fetch(:polymorphic, false) == true
      @absolute = options.fetch(:absolute, false) == true
      @always_include_linkage_data = options.fetch(:always_include_linkage_data, false) == true
      @eager_load_on_include = options.fetch(:eager_load_on_include, true) == true
    end

    alias_method :polymorphic?, :polymorphic
    alias_method :absolute?, :absolute

    def primary_key
      @primary_key ||= resource_klass._primary_key
    end

    def resource_klass
      @resource_klass ||= (absolute? ? Resource : @parent_resource).resource_klass_for(@class_name)
    end

    def table_name
      @table_name ||= resource_klass._table_name
    end

    def type
      @type ||= resource_klass._type.to_sym
    end

    def relation_name(options)
      case @relation_name
        when Symbol
          # :nocov:
          @relation_name
          # :nocov:
        when String
          @relation_name.to_sym
        when Proc
          @relation_name.call(options)
      end
    end

    def type_for_source(source)
      if polymorphic?
        resource = source.public_send(name)
        resource.class._type if resource
      else
        type
      end
    end

    def belongs_to?
      false
    end

    def readonly?
      @options[:readonly]
    end

    def redefined_pkey?
      belongs_to? && primary_key != resource_klass._default_primary_key
    end

    class ToOne < Relationship
      attr_reader :foreign_key_on

      def initialize(name, options = {})
        super
        @class_name = options.fetch(:class_name, name.to_s.camelize)
        @foreign_key ||= "#{name}_id".to_sym
        @foreign_key_on = options.fetch(:foreign_key_on, :self)
      end

      def belongs_to?
        foreign_key_on == :self
      end

      def polymorphic_type
        "#{name}_type" if polymorphic?
      end
    end

    class ToMany < Relationship
      attr_reader :reflect, :inverse_relationship

      def initialize(name, options = {})
        super
        @class_name = options.fetch(:class_name, name.to_s.camelize.singularize)
        @foreign_key ||= "#{name.to_s.singularize}_ids".to_sym
        @reflect = options.fetch(:reflect, true) == true
        @inverse_relationship = options.fetch(:inverse_relationship, parent_resource._type.to_s.singularize.to_sym) if parent_resource
      end
    end
  end
end
