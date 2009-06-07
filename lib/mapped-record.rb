#  See +attr_mapped+ or the README for details.
#
#
#  Created by Henry Hsu on 2009-06-07.
#  Copyright 2009 Qlane. All rights reserved.
# 

$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'mapped-record/hash/mappable'
require 'mapped-record/mapping'

module MappedRecord
  VERSION = '0.0.1' # :nodoc:

  IMPLICIT = 0 # :nodoc:
  NAMESPACE = 1 # :nodoc:
  EXPLICIT = 2 # :nodoc:

  class << self
    def included base #:nodoc:
      base.extend ClassMethods
    end
  end
  
  #--
  # TODO subclass this to signify each kind of error
  #++
  class MappingError < StandardError; end # :nodoc:

  module ClassMethods
    # Assigns a mapping for the current ActiveRecord class.
    #
    #  class Person < ActiveRecord::Base
    #    attr_mapped 'PBName', 'PBAddress', 'PBEmail', { :namespace => 'Email' }
    #  end
    #
    # Given a list of strings, those keys will be mapped automatically to downcase and
    # underscored attributes. (Specify these first).
    # 
    # Configuration options:
    # [<tt>:id</tt>]
    #   The key to map to the primary key.
    #    attr_mapped { :id => 'Key' }
    # [<tt>:serialize</tt>]
    #   Any keys to serialize after mapping.
    #    attr_mapped 'Array', 'Blob', { :serialize => ['Array', 'Blob'] }
    # [<tt>:filter</tt>]
    #   Specify a hash of keys and procs to call before assigning to attributes.
    #    attr_mapped 'Date', { :after => { 'Date' => Proc.new { ... } } }
    # [<tt>:namespace</tt>]
    #   A prefix string to remove before automatically mapping.
    #    attr_mapped 'PBOne', 'PBTwo', { :namespace => 'PB' }
    # [<tt>'key' => :attribute, 'key2' => :attribute2, ...</tt>]
    #   As many manual mappings as needed.
    def attr_mapped(*map_attrs)
      attr_mapped_named(class_name, *map_attrs)
    end
    
    # Assigns mappings to a name.
    #
    #  class Person < ActiveRecord::Base
    #    attr_mapped_named :public, 'PBName', 'PBAddress', 'PBEmail', { :namespace => 'Email' }
    #  end
    #
    # The mapping can then be used with dynamic create and update methods.
    # From the example above:
    #   p = Person.create_with_public({ 'PBName' => 'Mr. Name' })
    #   p.update_with_public({ 'PBName' => 'Full Name' })
    def attr_mapped_named(named_mapping = nil, *map_attrs)
      include InstanceMethods

      unless self.respond_to?(:attr_mapped_serialized)
        class_inheritable_accessor :attr_mapped_serialized
        write_inheritable_attribute :attr_mapped_serialized, Hash.new
      end

      unless self.respond_to?(:attr_hashed_id)
        class_inheritable_accessor :attr_hashed_id
        write_inheritable_attribute :attr_hashed_id, ''
      end

      raise ArgumentError, "Mapping name not given." if named_mapping.nil?
      raise MappingError, "No options given." if map_attrs.blank?

      options = map_attrs.extract_options!

      serialize_mappings = []

      options.each_pair do |key, value|
        case key
        when :id
          self.attr_hashed_id = value.to_s
        when :serialize
          keys = [value.to_s] unless value.kind_of?(Array) # TODO if-else blocks probably more efficient
          keys = value.collect { |v| v.to_s } if value.kind_of?(Array)
          serialize_mappings |= keys
        end
      end
      options.delete(:id)
      options.delete(:serialize)

      map_attrs << options
      Mapping.create named_mapping, *map_attrs

      if Mapping.has?(named_mapping)
        self.instance_eval %Q{ def create_with_#{named_mapping}(hash); create_with(hash, :#{named_mapping}); end; }
        self.class_eval %Q{ def update_with_#{named_mapping}(hash); update_with(hash, :#{named_mapping}); end }
        self.attr_mapped_serialized[named_mapping] ||= Hash.new
        self.attr_mapped_serialized[named_mapping] = update_serialized(named_mapping)
      end

      serialize_mappings.each do |attr|
        raise MappingError, "Serializing :id not allowed." if !self.attr_hashed_id.blank? && attr == self.attr_hashed_id        
        to_serialize = Mapping[named_mapping][attr][:to].to_sym

        # need to know serialized attributes to 'watch'
        self.attr_mapped_serialized[named_mapping][attr] = to_serialize

        self.instance_eval { serialize to_serialize }
      end
    end

    # Accepts a hash to map and creates the Active Record object with its values.
    def create_with(hash = {}, named_mapping = nil)
      named_mapping = self.class_name unless named_mapping

      self.create(with_attributes(named_mapping, hash)) do |r|
        id = hash[self.attr_hashed_id]
        r.id = id if id
      end
    end

    # A helper to check if the Active Record object responds to mapped-record methods.
    def acts_like_mapped?
      true
    end

    # Maps the values in +hash+ with +named_mapping+ for use in Active Record.
    def with_attributes(named_mapping, hash)
      attrs = hash.map_with(named_mapping)
      attrs.delete(:id) if attrs[:id]
      attrs
    end

    # Maintains that +serialize+ is set for correct attribute.
    def update_serialized(named_mapping)
      self.attr_mapped_serialized[named_mapping].inject({}) do |result, element|
        key = element.first
        serialized_as = element.last

        to_serialize = Mapping[named_mapping][key][:to].to_sym
        if to_serialize != serialized_as
          warn "[MappedRecord] overriding :#{serialized_as} with :#{to_serialize}, will not remove 'serialize :#{serialized_as}'"
          self.instance_eval { serialize to_serialize }
          result[key] = to_serialize
        end
      end
    end

    private :update_serialized
  end

  module InstanceMethods
    # Accepts a hash to map and update the object with.
    def update_with(hash = {}, named_mapping = nil)
      named_mapping = self.class.class_name unless named_mapping
      
      self.attributes = self.class.with_attributes(named_mapping, hash)

      if !self.changes.blank?
        self.save
      else
        false
      end
    end
  end
end

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, MappedRecord)
end
