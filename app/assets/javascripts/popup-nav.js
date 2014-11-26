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

  function handleClick(event) {
    var isPopupNavExpanded = popupNav.hasClass(navExpandedClass);

    event.preventDefault();

    if (isPopupNavExpanded) {
      removeNavExpandedClass();
    } else {
      addNavExpandedClass();
    }
  }

  arrowIcon.click(handleClick);
});

