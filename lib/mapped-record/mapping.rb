module MappedRecord
  class Mapping  
    class << self
      # Assigns a named mapping accessible throughout the runtime environment.
      #
      #  Mapping.create :my_mapping, 'Ready', 'Set', 'Go'
      #
      # The mapping is then accessible from <tt>Mapping[:my_mapping]</tt>
      #
      # Given a list of strings, those keys will be mapped automatically to downcase and
      # underscored attributes. (Specify these first).
      # 
      # Configuration options:
      # [<tt>:filter</tt>]
      #   Specify a hash of keys and procs to call before assigning to attributes.
      #    attr_mapped 'Date', { :after => { 'Date' => Proc.new { ... } } }
      # [<tt>:namespace</tt>]
      #   A prefix string to remove before automatically mapping.
      #    attr_mapped 'PBOne', 'PBTwo', { :namespace => 'PB' }
      # [<tt>'key' => :target, 'key2' => :target2, ...</tt>]
      #   As many manual mappings as needed.
      def create(mapping_name, *map_attrs)
        raise MappingError, "Not creating mapping with nil name" if mapping_name.nil?
        named_mappings[mapping_name] ||= Hash.new

        options = map_attrs.extract_options!
        verbose = parse_verbose(options)

        serialize_mappings = []
        namespace = nil
        type = IMPLICIT

        options.each_pair do |key, value|
          case key
          when :namespace
            namespace = value.to_s unless value.to_s.blank?
          when :filter
            value.each_pair do |attr, proc|
              named_mappings[mapping_name][attr.to_s] ||= Hash.new
              named_mappings[mapping_name][attr.to_s][:filter] = proc
            end
          when String, Symbol # deals with explicit mappings
            raise MappingError, "Must be symbol" unless value.kind_of?(Symbol)
            update_mapping(mapping_name, key, value.to_sym, EXPLICIT)
          end
        end

        mapping_temp = Hash.new

        map_attrs.each do |attr|
          raise MappingError, "Must be string or symbol." unless attr.kind_of?(String) or attr.kind_of?(Symbol)

          mapped_attr = attr.to_s
          if namespace
            match = mapped_attr[/^#{namespace}/]
            raise MappingError, "Causes mapping to be ''" if mapped_attr == match
            if match
              mapped_attr = mapped_attr.sub(/^#{namespace}/, '')
              type = NAMESPACE
            end
          end
          mapped_attr = mapped_attr.underscore.gsub(' ', '_')
          update_mapping(mapping_name, attr, mapped_attr.to_sym, type)
        end

        named_mappings[mapping_name]
      end

      def parse_verbose(options) # :nodoc:
        if !options[:verbose].nil? && (options[:verbose].kind_of?(FalseClass) || options[:verbose].kind_of?(TrueClass))
          verbose = options[:verbose]
          options.delete(:verbose) 
          verbose
        end
      end

      # Returns true if mapping of +mapping_name+ is assigned.
      def has?(mapping_name)
        named_mappings.include?(mapping_name)
      end

      # Returns true of no mappings are assigned.
      def empty?
        named_mappings.empty?
      end

      # Returns true of no mappings are assigned.
      def blank?
        named_mappings.blank?
      end

      # Clear all mappings.
      def reset
        named_mappings.clear
      end

      # Access named mappings straight from the class.
      def [](key)
        named_mappings[key]
      end

      # Assign mappings straight from the class.
      def []=(key, values)
        create(key, *values)
      end

      attr_accessor :named_mappings # :nodoc:

      def named_mappings # :nodoc:
        @named_mappings ||= Hash.new
      end

      private :named_mappings

      def update_mapping(mapping_name, key, value, type) # :nodoc:
        named_mapping = named_mappings[mapping_name]
        named_mapping[key] ||= Hash.new

        if named_mapping[key][:to].nil? or type >= named_mapping[key][:type]
          raise MappingError, "Multiple keys pointing to the same symbol" unless named_mapping.select { |key_name, mapping| key_name != key && mapping[:to] == value }.blank?
          named_mapping[key][:to] = value and named_mapping[key][:type] = type
        end
      end

      private :update_mapping
    end
  end
end

Mapping = MappedRecord::Mapping
