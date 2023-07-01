require "./spec_helper"

describe Marten::Core::Validator::URL do
  describe "::valid?" do
    it "returns true for valid URLs" do
      {
        "http://www.martenframework.com/",
        "HTTP://WWW.MARTENFRAMEWORK.COM/",
        "http://localhost/",
        "http://example.com/",
        "http://example.com:0",
        "http://example.com:0/",
        "http://example.com:65535",
        "http://example.com:65535/",
        "http://example.com./",
        "http://www.example.com/",
        "http://www.example.com:8000/test",
        "http://valid-with-hyphens.com/",
        "http://subdomain.example.com/",
        "http://a.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "http://200.8.9.10/",
        "http://200.8.9.10:8000/test",
        "http://su--b.valid-----hyphens.com/",
        "http://example.com?something=value",
        "http://example.com/index.php?something=value&another=value2",
        "https://example.com/",
        "ftp://example.com/",
        "ftps://example.com/",
        "http://foo.com/blah_blah",
        "http://foo.com/blah_blah/",
        "http://foo.com/blah_blah_(wikipedia)",
        "http://foo.com/blah_blah_(wikipedia)_(again)",
        "http://www.example.com/wpstyle/?p=364",
        "https://www.example.com/foo/?bar=baz&inga=42&quux",
        "http://✪df.ws/123",
        "http://userid@example.com",
        "http://userid@example.com/",
        "http://userid@example.com:8080",
        "http://userid@example.com:8080/",
        "http://userid@example.com:65535",
        "http://userid@example.com:65535/",
        "http://userid:@example.com",
        "http://userid:@example.com/",
        "http://userid:@example.com:8080",
        "http://userid:@example.com:8080/",
        "http://userid:password@example.com",
        "http://userid:password@example.com/",
        "http://userid:password@example.com:8",
        "http://userid:password@example.com:8/",
        "http://userid:password@example.com:8080",
        "http://userid:password@example.com:8080/",
        "http://userid:password@example.com:65535",
        "http://userid:password@example.com:65535/",
        (
          "https://userid:paaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaassword@example.com"
        ),
        (
          "https://userid:paaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaassword@example.com:8080"
        ),
        (
          "https://useridddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" +
            "ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" +
            "ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" +
            "dddddddddddddddddddddd:password@example.com"
        ),
        (
          "https://useridddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" +
            "ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" +
            "ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" +
            "ddddddddddddddddd:password@example.com:8080"
        ),
        "http://142.42.1.1/",
        "http://142.42.1.1:8080/",
        "http://➡.ws/䨹",
        "http://⌘.ws",
        "http://⌘.ws/",
        "http://foo.com/blah_(wikipedia)#cite-1",
        "http://foo.com/blah_(wikipedia)_blah#cite-1",
        "http://foo.com/unicode_(✪)_in_parens",
        "http://foo.com/(something)?after=parens",
        "http://☺.damowmow.com/",
        "http://martenframework.com/events/#&product=browser",
        "http://j.mp",
        "ftp://foo.bar/baz",
        "http://foo.bar/?q=Test%20URL-encoded%20stuff",
        "http://مثال.إختبار",
        "http://例子.测试",
        "http://उदाहरण.परीक्षा",
        "http://-.~_!$&'()*+,;=%40:80%2f@example.com",
        "http://xn--7sbb4ac0ad0be6cf.xn--p1ai",
        "http://1337.net",
        "http://a.b-c.de",
        "http://223.255.255.254",
        "ftps://foo.bar/",
        "http://10.1.1.254",
        "http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html",
        "http://[::192.9.5.5]/ipng",
        "http://[::ffff:192.9.5.5]/ipng",
        "http://[::1]:8080/",
        "http://0.0.0.0/",
        "http://255.255.255.255",
        "http://224.0.0.0",
        "http://224.1.1.1",
        "http://111.112.113.114/",
        "http://88.88.88.88/",
        "http://11.12.13.14/",
        "http://10.20.30.40/",
        "http://1.2.3.4/",
        "http://127.0.01.09.home.lan",
        "http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.example.com",
        "http://example.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com",
        "http://example.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        (
          "http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaa" +
            "aaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ),
        "http://dashintld.c-m",
        "http://multipledashintld.a-b-c",
        "http://evenmoredashintld.a---c",
        "http://dashinpunytld.xn---c",
      }.each do |url|
        Marten::Core::Validator::URL.valid?(url).should be_true, "#{url} should be valid"
      end
    end

    it "returns false for invalid URLs" do
      {
        "",
        "no_scheme",
        "foo",
        "http://",
        "http://example",
        "http://example.",
        "http://example.com:-1",
        "http://example.com:-1/",
        "http://example.com:000000080",
        "http://example.com:000000080/",
        "http://.com",
        "http://invalid-.com",
        "http://-invalid.com",
        "http://invalid.com-",
        "http://invalid.-com",
        "http://inv-.alid-.com",
        "http://inv-.-alid.com",
        "file://localhost/path",
        "git://example.com/",
        "http://.",
        "http://..",
        "http://../",
        "http://?",
        "http://??",
        "http://??/",
        "http://#",
        "http://##",
        "http://##/",
        "http://foo.bar?q=Spaces should be encoded",
        "//",
        "//a",
        "///a",
        "///",
        "http:///a",
        "foo.com",
        "rdar://1234",
        "h://test",
        "http:// shouldfail.com",
        ":// should fail",
        "http://foo.bar/foo(bar)baz quux",
        "http://-error-.invalid/",
        "http://dashinpunytld.trailingdot.xn--.",
        "http://dashinpunytld.xn---",
        "http://-a.b.co",
        "http://a.b-.co",
        "http://a.-b.co",
        "http://a.b-.c.co",
        "http:/",
        "http://",
        "http://",
        "http://1.1.1.1.1",
        "http://123.123.123",
        "http://3628126748",
        "http://123",
        "http://000.000.000.000",
        "http://016.016.016.016",
        "http://192.168.000.001",
        "http://01.2.3.4",
        "http://01.2.3.4",
        "http://1.02.3.4",
        "http://1.2.03.4",
        "http://1.2.3.04",
        "http://.www.foo.bar/",
        "http://.www.foo.bar./",
        "http://[::1:2::3]:8/",
        "http://[::1:2::3]:8080/",
        "http://[]",
        "http://[]:8080",
        "http://example..com/",
        "http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.example.com",
        "http://example.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com",
        "http://example.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        (
          "http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaa." +
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaa" +
            "aaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaa" +
            "aaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaa"
        ),
        "https://test.[com",
        "http://@example.com",
        "http://:@example.com",
        "http://:bar@example.com",
        "http://foo@bar@example.com",
        "http://foo/bar@example.com",
        "http://foo:bar:baz@example.com",
        "http://foo:bar@baz@example.com",
        "http://foo:bar/baz@example.com",
        "http://invalid-.com/?m=foo@example.com",
        "http://www.martenframework.com/\n",
        "http://[::ffff:192.9.5.5]\n",
        "http://www.martenframework.com/\r",
        "http://[::ffff:192.9.5.5]\r",
        "http://www.marten\rframework.com/",
        "http://[::\rffff:192.9.5.5]",
        "http://\twww.martenframework.com/",
        "http://\t[::ffff:192.9.5.5]",
        "http://www.asdasdasdasdsadfm.com.br ",
        "http://www.asdasdasdasdsadfm.com.br z",
      }.each do |url|
        Marten::Core::Validator::URL.valid?(url).should be_false, "#{url} should not be valid"
      end
    end
  end
end
