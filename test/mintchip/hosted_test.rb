class Mintchip::HostedTest < MiniTest::Unit::TestCase

  # Testing web APIs is a pain in the ass. TODO!
  def test_info
    assert_equal 3, hosted.info
  end

  def setup
    OpenSSL::PKCS12.expects(:new).with("omg", "wtf").returns(p12)
  end

  private

  def p12
    @p12 ||= stub(key: "key", certificate: "certificate")
  end

  def hosted
    @hosted ||= Mintchip::Hosted.new("omg", "wtf")
  end

end
