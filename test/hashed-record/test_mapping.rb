require File.dirname(__FILE__) + '/../test_helper.rb'

class TestMapping < Test::Unit::TestCase
  context "Mapping" do
    setup do
      @sample_hash = {"PhotoCount"=>1, "KeyList"=>["2"], "KeyPhotoKey"=>"2", "RollID"=>3, "RollDateAsTimerInterval"=>263609145.0, "RollName"=>"May 9, 2009"}
    end
    
    context "creating named mapping" do
      setup do
        @mapping_name = :test_mapping
        @@proc = Proc.new { |p| 'PROC-ED' }
        Mapping.create @mapping_name, 'ImplicitMapping', 'AnotherMapping', 'ForNamespaceMapping', 'ExplicitMapping' => :explicit, :namespace => 'ForNamespace', :filter => { 'ImplicitMapping' => @@proc }
      end

      should "have mapping named #{@mapping_name}" do
        assert Mapping.has?(@mapping_name)
        assert Mapping[@mapping_name].is_a?(Hash)
      end
      
      should "have #[] method" do
        assert_respond_to Mapping, :[]
      end
      
      should "have #[]= method do the same as #create" do
        assert_respond_to Mapping, :[]=
        Mapping[:alt_test_mapping] = 'ImplicitMapping', 'AnotherMapping', 'ForNamespaceMapping', {'ExplicitMapping' => :explicit, :namespace => 'ForNamespace', :filter => { 'ImplicitMapping' => @@proc }}
        assert_equal Mapping[:alt_test_mapping], Mapping[@mapping_name]
      end

      should_map_implicit :test_mapping, 'ImplicitMapping', :implicit_mapping
      should_map_implicit :test_mapping, 'AnotherMapping', :another_mapping
      should_map_namespace :test_mapping, 'ForNamespaceMapping', :mapping
      should_map_explicit :test_mapping, 'ExplicitMapping', :explicit

      should "map proc" do
        assert_same @@proc, Mapping[@mapping_name]['ImplicitMapping'][:filter]
      end
    end

    context "with options" do
      
      setup { Mapping.reset }
      
      should "allow symbol mapping" do
        assert_nothing_raised(MappedRecord::MappingError) { Mapping.create :mixed, :key => :symbol }
        Mapping.reset
        assert_nothing_raised(MappedRecord::MappingError) { Mapping.create :mixed, :symbol }
      end
      
      should "not allow non-symbol mappings" do
        assert_raise(MappedRecord::MappingError) { Mapping.create :mixed, :key => 1 }
        assert_raise(MappedRecord::MappingError) { Mapping.create :mixed, :key => Fixnum }
        assert_raise(MappedRecord::MappingError) { Mapping.create :mixed, :key => 'String' }
        assert_raise(MappedRecord::MappingError) { Mapping.create :mixed, 1 }
        assert_raise(MappedRecord::MappingError) { Mapping.create :mixed, Fixnum }
      end

      context "with mixed options" do
        # 4 combinations of symbol:string
        # validate :to is string or symbol
        setup do
          Mapping.create :mixed, :SymbolMapping, 'StringMapping', :symbol_key => :key, "symbol_key" => :other_key
        end

        should_map_explicit :mixed, :symbol_key, :key
        should_map_explicit :mixed, "symbol_key", :other_key
        should_map_implicit :mixed, 'StringMapping', :string_mapping
        should_map_implicit :mixed, :SymbolMapping, :symbol_mapping
      end
    end

    context "resetting mappings" do
      should "have #reset method" do
        assert_respond_to(Mapping, :reset)
      end
      
      should "clear mappings" do
        assert(!Mapping.blank?, "Mapping is blank.")
        Mapping.reset
        assert(Mapping.blank?, "Mappings should be blank.")
      end
    end

    context "called multiple times" do

      # Namespaces work on a per-#attr_mapped basis
      context "with different namespaces" do
        setup do
          Mapping.create :diff_ns, 'ForNamespaceMapping', :namespace => 'ForNamespace'
          Mapping.create :diff_ns, 'ForNamespaceMapping', :namespace => 'For'
        end

        should_map_namespace :diff_ns, 'ForNamespaceMapping', :namespace_mapping
      end

      context "with all (naturally ordered) mappings" do
        setup do
          Mapping.create :natural, 'OrderedMapping'
          Mapping.create :natural, 'OrderedMapping', :namespace => 'Ordered'
          Mapping.create :natural, 'OrderedMapping' => :ordered
        end

        should_map_explicit :natural, 'OrderedMapping', :ordered
      end

      context "with all (inverse ordered) mappings" do
        setup do
          Mapping.create :reversed, 'OrderedMapping' => :ordered
          Mapping.create :reversed, 'OrderedMapping', :namespace => 'Ordered'
          Mapping.create :reversed, 'OrderedMapping'
        end

        should_map_explicit :reversed, 'OrderedMapping', :ordered
      end
    end

    # ==================
    # = Tests overlaps =
    # ==================
    context "with namespace and explicit overlap" do
      setup { Mapping.create :ns_e_overlap, 'ImplicitMapping', 'AnotherMapping', 'ExplicitMapping' => :explicit_mapping, :namespace => 'Explicit' }
      should_map_explicit :ns_e_overlap, 'ExplicitMapping', :explicit_mapping
    end

    context "with namespace and implicit overlap" do
      setup { Mapping.create :ns_i_overlap, 'ImplicitMapping', 'ImplicitMappingSecond', 'ExplicitMapping' => :explicit_mapping, :namespace => 'Implicit' }
      should_map_namespace :ns_i_overlap, 'ImplicitMapping', :mapping
    end

    context "with explicit and implicit overlap" do
      setup { Mapping.create :e_i_overlap, 'ImplicitMapping', 'ImplicitMapping' => :explicit_mapping, :namespace => 'NoMatch' }
      should_map_explicit :e_i_overlap, 'ImplicitMapping', :explicit_mapping
    end

    # ========================
    # = Raising MappingError =
    # ========================
    should "raise MappingError when #namespace causes mapping to be ''" do
      assert_raises MappedRecord::MappingError do
        Mapping.create :ns_to_blank, 'ImplicitMapping', 'ImplicitMappingSecond', :namespace => 'ImplicitMapping'
      end
    end

    should "raise MappingError with many-to-one mappings" do # because it will have unexpected results
      assert_raises MappedRecord::MappingError do
        Mapping.create :many_to_one, 'Root', 'MappingWithRoot', :namespace => 'MappingWith'
      end
    end
    
    should "raise MappingError with un-named mapping" do
      Mapping.reset
      assert_raises MappedRecord::MappingError do
        Mapping.create nil, 'Root', 'MappingWithRoot', :namespace => 'MappingWith'
      end
      assert(Mapping.blank?, "Mapping shouldn't be set.")
    end
    
    # should "raise MappingError with invalid mapping names" do
    #   Mapping.reset
    #   assert_raise(MappedRecord::MappingError) do
    #     Mapping.create 1, 'Root'
    #   end
    # end
  end
end