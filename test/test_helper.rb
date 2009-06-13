require 'stringio'
require 'rubygems'
require 'test/unit'
gem 'thoughtbot-shoulda', ">= 2.9.0"
require 'shoulda'

gem 'sqlite3-ruby'

require 'active_record'
require 'active_support'

require File.dirname(__FILE__) + '/../lib/mapped-record'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])

def reset_class class_name
  ActiveRecord::Base.send(:include, MappedRecord)
  Object.send(:remove_const, class_name) rescue nil
  klass = Object.const_set(class_name, Class.new(ActiveRecord::Base))
  klass.class_eval{ include MappedRecord }
  klass
end
 
def reset_table table_name, &block
  block ||= lambda{ true }
  ActiveRecord::Base.connection.create_table :dummies, {:force => true}, &block
end
 
def modify_table table_name, &block
  ActiveRecord::Base.connection.change_table :dummies, &block
end
 
def rebuild_model(*args)
  ActiveRecord::Base.connection.create_table :dummies, :force => true do |t|
    t.string :name
    t.datetime :date
    t.references :key_photo
    t.integer :photo_count
    t.text :key_list
    t.references :library
  end
  rebuild_class(*args)
end
 
def rebuild_class(*args)
  ActiveRecord::Base.send(:include, MappedRecord)
  Object.send(:remove_const, "Dummy") rescue nil
  Object.const_set("Dummy", Class.new(ActiveRecord::Base))
  Dummy.class_eval do
    include MappedRecord
  end
  if args.size > 0
    Dummy.class_eval do
      attr_mapped_named(*args)
    end  
  end
end

def should_map name, field, mapping, type, klass=Mapping
  type_s = ''
  case type
  when MappedRecord::EXPLICIT
    type_s = 'explicit'
  when MappedRecord::IMPLICIT
    type_s = 'implicit'
  when MappedRecord::NAMESPACE
    type_s = 'namespace'
  else
    raise "Unknown mapping type"
  end

  should "map #{type_s} from #{field.kind_of?(Symbol) ? ':' : ''}#{field} => #{mapping} for mapping :#{name}" do
    assert_not_nil(klass.blank?, "Mappings not set up correctly.")
    assert_not_nil(klass[name], "Mapping #{name} not set up correctly.")
    assert_not_nil(klass[name][field], "Mapping #{name}'s #{field} not set up correctly.")
    assert_equal(mapping, klass[name][field][:to], "Mapping doesn't match.")
    assert_equal(type, klass[name][field][:type], "Mapping type doesn't match.")
  end
end

def should_map_explicit name, field, mapping, klass=Mapping
  should_map name, field, mapping, MappedRecord::EXPLICIT, klass
end

def should_map_implicit name, field, mapping, klass=Mapping
  should_map name, field, mapping, MappedRecord::IMPLICIT, klass
end

def should_map_namespace name, field, mapping, klass=Mapping
  should_map name, field, mapping, MappedRecord::NAMESPACE, klass
end
