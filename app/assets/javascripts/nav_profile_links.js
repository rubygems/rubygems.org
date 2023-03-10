function renderProfileLinks(selector, response) {
  var nav = $(selector);
  if (!!response.trim()) {
    nav.html(response);
  }
  nav.addClass("nav-loaded");
}

function makeNavRequest(url, success) {
  $.ajax({
    type: "get",
    url: url,
    success: success,
  });
}

$(function () {
  var getNavProfileLinks = "/nav_profile_links";
  var navProfileLinksSelector = "#nav_profile_links";
  var getMobileNavProfileLinks = "/mobile_nav_profile_links";
  var mobileNavProfileLinksSelector = "#mobile_nav_profile_links";

  function navProfileLinksSuccess(resp) {
    renderProfileLinks(navProfileLinksSelector, resp);
    // function defined in popup-nav.js
    bindPopupNav();
  }

  function mobileNavProfileLinksSuccess(resp) {
    renderProfileLinks(mobileNavProfileLinksSelector, resp);
    // function defined in mobile-nav.js
    bindMobileNav();
  }

  makeNavRequest(getNavProfileLinks, (resp) => navProfileLinksSuccess(resp));
  makeNavRequest(getMobileNavProfileLinks, (resp) =>
    mobileNavProfileLinksSuccess(resp)
  );
});
