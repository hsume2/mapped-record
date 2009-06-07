require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestMappable < Test::Unit::TestCase
  context "Hash" do
    setup do
      @hash = {"PhotoCount"=>1, "KeyList"=>["2"], "KeyPhotoKey"=>"2", "RollID"=>3, "RollDateAsTimerInterval"=>263609145.0, "RollName"=>"May 9, 2009"}
    end

    should "have #map_with method" do
      assert_respond_to @hash, :map_with
    end

    context "with mapping" do
      setup do
        Mapping.create :iphoto_roll2, 'PhotoCount', 'KeyList', 'RollName', 'RollID', :namespace => 'Roll', 'KeyPhotoKey' => :key_photo_id, 'RollDateAsTimerInterval' => :date, :filter => { 'RollDateAsTimerInterval' => Proc.new { |p| Time.at(p.to_f + 978307200) } }
      end
      
      should "map properly" do
        mapped_hash = @hash.map_with(:iphoto_roll2)
        assert_not_nil mapped_hash
        assert_equal 1, mapped_hash[:photo_count]
        assert_equal "2", mapped_hash[:key_photo_id]
        assert_equal ["2"], mapped_hash[:key_list]
        assert_equal Time.at(263609145.0 + 978307200), mapped_hash[:date]
        assert_equal "May 9, 2009", mapped_hash[:name]
        assert_equal 3, mapped_hash[:id]
      end
    end
  end
end