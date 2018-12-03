$(function() {
  var arrowIcon        = $('.header__popup-link');
  var popupNav         = $('.header__popup__nav-links');

  var navExpandedClass = 'is-expanded';

  function removeNavExpandedClass() {
    popupNav.removeClass(navExpandedClass);
  }

  function addNavExpandedClass() {
    popupNav.addClass(navExpandedClass);
  }

  arrowIcon.click(function(e){
    var nav = {expandedClass: navExpandedClass, popUp: popupNav}
    handleClick(e, nav, removeNavExpandedClass, addNavExpandedClass);
  });
});

