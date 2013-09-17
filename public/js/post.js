$("header.main .inner h1 a").click(function() {
  window.location.hash = "";
  window.scrollTo(0,0);
  return false;
});

// $("header.main .inner.me a.left").show();


$(function() {

  // replace blog header links with article title
  var start = $("article header").offset().top;
  var offset = 0;

  var headerLinks = $("header.main .inner ul");
  var headerTitle = $("header.main .inner h1");

  var actualTitle = $("article header .title").text();
  headerTitle.find("a").text(actualTitle);

  if ($("article.post").size() == 1) {
    $.event.add(window, "scroll", function() {
      var p = $(window).scrollTop();
      var flip = p > (start - offset);

      headerLinks.css('display', flip ? 'none' : 'block');
      headerTitle.css('display', flip ? 'block' : 'none');
    });
  }


  // easy footnotes
  $("article small").each(function(i) {
    var note = "<sup>" + (i+1) + "</sup>";
    $(this).before(note).prepend(note);
  });

  // dynamically prepend an anchor link to every h2
  // $("article .body h2").prepend("<span class=\"anchor\"></span><span class=\"block\"></span>");
  // $("span.block").each(function(i, elem) {
  //   var id = this.parentNode.id;
  //   this.parentNode.id = null;
  //   $(this).prev(".anchor")[0].id = id;
  //   $(this).attr("href", "#" + id);
  // });

});