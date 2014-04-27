$("header.main .inner h1 a, article .nav .toc h6 a").click(function() {
  window.location.hash = "";
  window.scrollTo(0,0);
  return false;
});


$(function() {

  // replace blog header links with article title
  var start = $("article header").offset().top;
  var offset = 0;

  var headerLinks = $("header.main .inner ul");
  var headerTitle = $("header.main .inner h1");

  var actualTitle = $("article header .title").text();
  headerTitle.find("a").text(actualTitle);

  var navLinks = $(".nav ul li a").get().reverse();
  var navItems = $(".nav ul li, .nav h6");
  var navTop = $(".nav h6");

  if ($("article.post").size() == 1) {
    $.event.add(window, "scroll", function() {
      var p = $(window).scrollTop();

      // header title
      var flip = p > (start - offset);
      headerLinks.css('display', flip ? 'none' : 'block');
      headerTitle.css('display', flip ? 'block' : 'none');

      var found = false;
      $.each(navLinks, function(i, link) {
        var li = $(link.parentNode);
        link = $(link);
        var anchor = link.attr("href");
        var location = $("h2" + anchor + ",h3" + anchor).offset().top;
        if (location < (p + 100)) {
          if (!link.hasClass("active")) {
            navItems.removeClass("active");
            li.addClass("active");
          }
          found = true;
          return false;
        }
      });
      if (!found) {
        if (!navTop.hasClass("active")) {
          navItems.removeClass("active");
          navTop.addClass("active");
        }
      }
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