$("header.main .inner.article a.right").click(function() {
  window.location.hash = "";
  window.scrollTo(0,0);
  return false;
});

$("header.main .inner.me a.left").show();

// dynamically prepend an anchor link to every h2
$("article .body h2").prepend("<span class=\"anchor\"></span><a class=\"block\"></a>");
$("a.block").each(function(i, elem) {
  var id = this.parentNode.id;
  this.parentNode.id = null;
  $(this).prev(".anchor")[0].id = id;
  $(this).attr("href", "#" + id);
});

$(function() {
  var articleHeader = $('article header');

  // var offset = $("header.main").outerHeight();
  var start = $(articleHeader).offset().top;
  var offset = 0;

  var headerMe = $("header.main .inner.me");
  var headerArticle = $("header.main .inner.article");
  headerArticle.find("h1").text($("article header .title").text());
  // headerArticle.find("time").text($("article header time").text());

  $.event.add(window, "scroll", function() {
    var p = $(window).scrollTop();
    var flip = p > (start - offset);

    headerMe.css('display', flip ? 'none' : 'block');
    headerArticle.css('display', flip ? 'block' : 'none');
  });

  // easy footnotes
  $("article small").each(function(i) {
    var note = "<sup>" + (i+1) + "</sup>";
    $(this).before(note).prepend(note);
  });

});