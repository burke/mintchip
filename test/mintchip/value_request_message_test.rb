require File.expand_path('../../test_helper', __FILE__)

class ValueRequestMessageTest < MiniTest::Unit::TestCase

  def test_pretty_much_everything
    msg = Mintchip::ValueRequestMessage.new(1000, "http://example.com", "", info)
    msg.expects(:random_bytes).with(4).returns(">@\xE6\x90")
    expected = "YDwwOqADCgEBojOhMTAvBAgQAAAAAAATJAQBAQQDABAAAQH/FhJodHRwOi8vZXhhbXBsZS5jb22ABD5A5pA="
    assert_equal expected, msg.to_base64
  end

  def test_loading_from_base64
    code = "YDwwOqADCgEBojOhMTAvBAgQAAAAAAATJAQBAQQDABAAAQH/FhJodHRwOi8vZXhhbXBsZS5jb22ABD5A5pA="
    vrm = Mintchip::ValueRequestMessage.from_base64(code)
    assert_equal "http://example.com", vrm.response_url
    assert_equal "", vrm.annotation
    assert_equal 1000, vrm.value
  end

  private

  def info
    stub(id: "1000000000001324", currency_code: 1)
  end

end
