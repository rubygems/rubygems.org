$(function () {
  var getNavProfileLinks = "/nav_profile_links";
  var navProfileLinksSelector = "#nav_profile_links";
  var getMobileNavProfileLinks = "/mobile_nav_profile_links";
  var mobileNavProfileLinksSelector = "#mobile_nav_profile_links";

  $.ajax({
    type: "get",
    url: getNavProfileLinks,
    success: function (resp) {
      renderProfileLinks(navProfileLinksSelector, resp);
      // function defined in popup-nav.js
      bindPopupNav();
    },
  });
  $.ajax({
    type: "get",
    url: getMobileNavProfileLinks,
    success: function (resp) {
      renderProfileLinks(mobileNavProfileLinksSelector, resp);
      // function defined in mobile-nav.js
      bindMobileNav();
    },
  });

  function renderProfileLinks(selector, response) {
    var nav = $(selector);
    if (!!response.trim()) {
      nav.html(response);
    }
    nav.addClass("nav-loaded");
  }
});
