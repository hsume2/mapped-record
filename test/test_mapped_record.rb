require File.dirname(__FILE__) + '/test_helper.rb'

class TestMappedRecord < Test::Unit::TestCase
  context "Dummy" do
    setup do
      rebuild_class
    end

    should "have #attr_mapped method" do
      assert_respond_to Dummy, :attr_mapped
    end

    should "have #attr_mapped_named method" do
      assert_respond_to Dummy, :attr_mapped_named
    end

    should "raise NameError when no mapping name and no options not given" do
      assert_raises MappedRecord::NameError do
        Dummy.class_eval do
          attr_mapped_named
        end
      end
    end

    should "raise MappingError when name given but options not given" do
      assert_raises MappedRecord::MappingError do
        rebuild_class 'some_name'
      end
    end

    # =======================
    # = Setting up mappings =
    # =======================
    context "when #attr_mapped" do
      context "untitled" do
        setup do
          Mapping.reset
          Dummy.class_eval do
            attr_mapped 'FullName', 'Email'
          end
        end

        should "map with class_name as default mapping name" do
          assert(Mapping.has?(Dummy.class_name), "Mapping name not #{Dummy.class_name}.")
        end

        should_map_implicit 'Dummy', 'FullName', :full_name
        should_map_implicit 'Dummy', 'Email', :email
      end
    end

    context "when #attr_mapped_named" do
      context "with dummy mapping and options" do

        setup do
          Mapping.reset
          @@proc = Proc.new { |p| 'PROC-ED' }
          rebuild_class :dummy, 'ImplicitMapping', 'AnotherMapping', 'ForNamespaceMapping', 'ExplicitMapping' => :explicit, :namespace => 'ForNamespace', :id => 'ForID', :filter => { 'ImplicitMapping' => @@proc }, :serialize => 'ForNamespaceMapping'
        end

        should_map_implicit :dummy, 'ImplicitMapping', :implicit_mapping
        should_map_implicit :dummy, 'AnotherMapping', :another_mapping
        should_map_namespace :dummy, 'ForNamespaceMapping', :mapping
        should_map_explicit :dummy, 'ExplicitMapping', :explicit

        should "map id" do
          assert_equal 'ForID', Dummy.attr_hashed_id
        end

        should "map proc" do
          assert_same @@proc, Mapping[:dummy]['ImplicitMapping'][:filter]
        end

        should "serialize" do
          assert Dummy.serialized_attributes.include?("mapping")
        end

        context "with indifferent access" do
          setup do
            rebuild_class :dummy2, :ImplicitMapping, :AnotherMapping, :ForNamespaceMapping, :ExplicitMapping => :explicit, :namespace => 'ForNamespace', :id => 'ForID', :filter => { :ImplicitMapping => @@proc }, :serialize => :ImplicitMapping
          end
          
          # using same tests as above
          should_map_implicit :dummy2, 'ImplicitMapping', :implicit_mapping
          should_map_implicit :dummy2, 'AnotherMapping', :another_mapping
          should_map_namespace :dummy2, 'ForNamespaceMapping', :mapping
          should_map_explicit :dummy2, 'ExplicitMapping', :explicit

          should "map proc" do
            assert_same @@proc, Mapping[:dummy2]['ImplicitMapping'][:filter]
          end

          should "serialize" do
            assert Dummy.serialized_attributes.include?("implicit_mapping")
          end
        end

        context "a subclass" do
          setup do
            class ::SubDummy < Dummy; end
          end

          should "map id" do
            assert_equal 'ForID', SubDummy.attr_hashed_id
          end

          should "serialize" do
            assert SubDummy.serialized_attributes.include?("mapping")
          end

          teardown do
            Object.send(:remove_const, "SubDummy") rescue nil
          end
        end
      end
      
      context "with multiple serializes" do
        setup do
          Mapping.reset
          rebuild_class :multiple_s, 'KeyOne', 'KeyTwo', :serialize => ['KeyOne', 'KeyTwo']
        end
        
        should "serialize :key_one and :key_two" do
          assert Dummy.serialized_attributes.include?("key_one")
          assert Dummy.serialized_attributes.include?("key_two")
        end
      end

      # ========================
      # = Raising MappingError =
      # ========================

      should "raise MappingError when #serialize and #id overlap" do
        assert_raises MappedRecord::MappingError do
          rebuild_class :ser, 'ImplicitMapping', 'AnotherMapping', 'ForNamespaceMapping', 'ExplicitMapping' => :explicit, :namespace => 'ForNamespace', :id => 'AnotherMapping', :serialize => 'AnotherMapping'
        end
      end

			should "raise NameError when mapping name has invalid characters" do
				assert_raises MappedRecord::NameError do
					rebuild_class 'name with spaces', 'ImplicitMapping'
          rebuild_class 'namewith|n\/al|#ch*r%ct!rs', 'ImplicitMapping'
        end
			end
			
			should "raise TargetError when serialize target is not String, Symbol or Array" do
				assert_raises MappedRecord::TargetError do
          rebuild_class :serialize_fail, 'ImplicitMapping', 'AnotherMapping', 'ForNamespaceMapping',  :serialize => Fixnum
					rebuild_class :serialize_fail, 'ImplicitMapping', 'AnotherMapping', 'ForNamespaceMapping',  :serialize => Proc.new{ |p| puts p }
        end
			end

      # ============================================
      # = #attr_mapped_named called multiple times =
      # ============================================
      context "called multiple times" do

        context "with serialized mapping being overridden" do
          setup do
            rebuild_class
            Dummy.class_eval do
              attr_mapped_named :overriding, 'AMapping', :serialize => 'AMapping'
              attr_mapped_named :overriding, 'AMapping' => :mapping
            end
          end

          should "update serialize" do
            assert Dummy.serialized_attributes.include?("mapping")
          end
        end
      end
    end

    # ======================
    # = Creating with hash =
    # ======================
    context "creating" do
      context "with named mapping" do
        setup do
          Mapping.reset
          rebuild_model
          Dummy.class_eval do
            attr_mapped_named :iphoto_roll, 'PhotoCount', 'KeyList', 'RollName', :namespace => 'Roll', 'KeyPhotoKey' => :key_photo_id, 'RollDateAsTimerInterval' => :date, :id => 'RollID', :serialize => 'KeyList', :filter => { 'RollDateAsTimerInterval' => Proc.new { |p| Time.at(p.to_f + 978307200) } }
          end
          @rand = rand(10000)
          @sample_hash = {"PhotoCount"=>1, "KeyList"=>["2"], "KeyPhotoKey"=>"2", "RollID"=>@rand, "RollDateAsTimerInterval"=>263609145.0, "RollName"=>"May 9, 2009"}
          @dummy = Dummy.create_with_iphoto_roll(@sample_hash)
          assert_not_nil @dummy
        end

        should "have dynamic #create_with_iphoto_roll method" do
          assert_respond_to Dummy, :create_with_iphoto_roll
        end

        should "not mass-assign #id" do
          assert !Dummy.with_attributes(:iphoto_roll, @sample_hash).include?(:id)
        end

        should "create properly" do
          assert_equal 1, @dummy.photo_count
          assert_equal 2, @dummy.key_photo_id
          assert_equal ["2"], @dummy.key_list
          assert_equal Time.at(263609145.0 + 978307200), @dummy.date
          assert_equal "May 9, 2009", @dummy.name
          assert_equal @rand, @dummy.id
        end

        should "have #update_with method" do
          assert_respond_to @dummy, :update_with
        end

        should "have dynamic #update_with_iphoto_roll method" do
          assert_respond_to @dummy, :update_with_iphoto_roll
        end

        should "fail with empty update" do
          assert !@dummy.update_with_iphoto_roll({})
        end

        should "fail updating with no changes" do
          assert !@dummy.update_with_iphoto_roll(@sample_hash)
        end

        context "then updating" do

          setup do
            @update_hash = {"PhotoCount"=>2, "KeyList"=>["2", "3"], "KeyPhotoKey"=>"3", "RollID"=>rand(10000), "RollDateAsTimerInterval"=>263609245.0, "RollName"=>"NewName"}
            assert_not_nil @dummy
          end

          should "update properly" do
            assert @dummy.update_with_iphoto_roll(@update_hash)
            assert_equal 2, @dummy.photo_count
            assert_equal 3, @dummy.key_photo_id
            assert_equal ["2", "3"], @dummy.key_list
            assert_equal Time.at(263609245.0 + 978307200), @dummy.date
            assert_equal "NewName", @dummy.name
            assert_equal @rand, @dummy.id
          end
        end
      end
    end
    
    # the rest relies on named mapping (above)
    context "with unnamed mapping" do
      setup do
        Mapping.reset
        rebuild_model
        Dummy.class_eval do
          attr_mapped 'PhotoCount', 'KeyList', 'RollName', :namespace => 'Roll', 'KeyPhotoKey' => :key_photo_id, 'RollDateAsTimerInterval' => :date, :id => 'RollID', :serialize => 'KeyList', :filter => { 'RollDateAsTimerInterval' => Proc.new { |p| Time.at(p.to_f + 978307200) } }
        end
        @rand = rand(10000)
        @sample_hash = {"PhotoCount"=>1, "KeyList"=>["2"], "KeyPhotoKey"=>"2", "RollID"=>@rand, "RollDateAsTimerInterval"=>263609145.0, "RollName"=>"May 9, 2009"}
        @dummy = Dummy.create_with(@sample_hash)
      end

      should "have #create_with method" do
        assert_respond_to Dummy, :create_with
      end

      should "create properly" do
        assert_not_nil @dummy
        assert_equal 1, @dummy.photo_count
        assert_equal 2, @dummy.key_photo_id
        assert_equal ["2"], @dummy.key_list
        assert_equal Time.at(263609145.0 + 978307200), @dummy.date
        assert_equal "May 9, 2009", @dummy.name
        assert_equal @rand, @dummy.id
      end

      context "then updating" do

        setup do
          @update_hash = {"PhotoCount"=>2, "KeyList"=>["2", "3"], "KeyPhotoKey"=>"3", "RollID"=>rand(10000), "RollDateAsTimerInterval"=>263609245.0, "RollName"=>"NewName"}
          assert_not_nil @dummy
        end

        should "update properly" do
          assert @dummy.update_with(@update_hash)
          assert_equal 2, @dummy.photo_count
          assert_equal 3, @dummy.key_photo_id
          assert_equal ["2", "3"], @dummy.key_list
          assert_equal Time.at(263609245.0 + 978307200), @dummy.date
          assert_equal "NewName", @dummy.name
          assert_equal @rand, @dummy.id
        end
      end
    end
  end
end
