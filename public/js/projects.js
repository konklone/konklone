$(function() {
  var navLinks = $(".projects .nav ul li a").get().reverse();
  var navItems = $(".projects .nav ul li");
  var navTop = $(".projects .nav ul li:first-child");
  var winHeight = $(window).height();
  var winOffset = (winHeight / 2) - 50;


  $.event.add(window, "scroll", function() {
    var p = $(window).scrollTop();

    var found = false;
    $.each(navLinks, function(i, link) {
      var li = $(link.parentNode);
      link = $(link);
      var anchor = link.attr("href");
      var location = $(anchor).offset().top;
      if (location < (p + winOffset)) {
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
});