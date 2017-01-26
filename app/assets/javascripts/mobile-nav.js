$(function() {
  // cache jQuery lookups into variables
  // so we don't have to traverse the DOM every time
  var sandwichIcon     = $('.header__club-sandwich');
  var header           = $('.header');
  var main             = $('main');
  var footer           = $('.footer');
  var signUpLink       = $('.header__nav-link.js-sign-up-trigger');
  var navExpandedClass = 'mobile-nav-is-expanded';
  var headerSeach      = $('.header__search');
  var headerLogo       = $('.header__logo-wrap');

  // variable to support mobile nav tab behaviour
  // * skipSandwichIcon is for skipping sandwich icon
  //   when you tab from "gem" icon
  // * tabDirection is for hiding and showing navbar
  //   when you tab in and out
  var skipSandwichIcon = true;
  var tabDirection     = true;

  function removeNavExpandedClass() {
    header.removeClass(navExpandedClass);
    main.removeClass(navExpandedClass);
    footer.removeClass(navExpandedClass);
  }

  function addNavExpandedClass() {
    header.addClass(navExpandedClass);
    main.addClass(navExpandedClass);
    footer.addClass(navExpandedClass);
  }

  function handleClick(event) {
    var isMobileNavExpanded = header.hasClass(navExpandedClass);

    event.preventDefault();

    if (isMobileNavExpanded) {
      removeNavExpandedClass();
    } else {
      addNavExpandedClass();
    }
  }

  function handleFocusIn() {
    if (skipSandwichIcon) {
      addNavExpandedClass();
      headerSeach.focus();
      skipSandwichIcon = false;
    } else {
      removeNavExpandedClass();
      headerLogo.focus();
      skipSandwichIcon = true;
    }
  }

  sandwichIcon.click(handleClick);

  sandwichIcon.on('focusin', handleFocusIn);

  signUpLink.on('focusin', function() {
    if (!tabDirection) {
      addNavExpandedClass();
    }
  });

  signUpLink.on('focusout', function() {
    if (tabDirection) {
      tabDirection = false;
      removeNavExpandedClass();
    } else {
      tabDirection = true;
      addNavExpandedClass();
    }
  });
});
