var is_local = (location.port == '4567');
var is_demo = 0;
if(is_local) {
  var root    = "http://0.0.0.0:4567";
  var jquery_src = "../../javascript/jquery-1.8.3.min.js";
} else {
  var root    = "http://api.expertdojo.com";
  var jquery_src = 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js';
}

function feedbacker() {
  if($("#pvtitle").attr("demo") == 'true') {
    is_demo = 1;
  }
  $.getScript(root + '/javascript/base.js', function()
  {
    $.getScript(root + '/javascript/append_pic.js', function()
    {
      if(is_demo) {
        var domain  = $("#pvtitle").attr("host");
        var target  = '///' + $("#pvtitle").attr("url");
      } else {
        var domain  = getDomainName(location.hostname);
        var target  = document.URL;
      }
      $("head").append('<link rel="stylesheet" href="' + root + '/css/' + domain + '.css" type="text/css" />');
      var funcen  = $("#recommend_region").attr("alg");
      var pvuid   = getCookie("pvuid");
      var pvtitle = $("#pvtitle").text();
      var pvthumb = $("#pvthumb img").attr("src");
      var pvpublic = $("#pvtitle").attr("public");
      launch_request(domain, target, root, pvuid, pvtitle, pvthumb, funcen, pvpublic);
    });
  });
}

function jQChecker() {
  if(typeof jQuery=='undefined') {
    var headTag = document.getElementsByTagName("head")[0];
    var jqTag = document.createElement('script');
    jqTag.type = 'text/javascript';
    jqTag.src = jquery_src;
    jqTag.onload = feedbacker;
    headTag.appendChild(jqTag);
  } else {
    feedbacker();
  }
}

jQChecker();
