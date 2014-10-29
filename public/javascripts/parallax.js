$(function() {

  $(document).ready(function() {

    if ($('body').hasClass('body--index')) {
      setup();
    }
  });

  var requestAnimationFrame = window.requestAnimationFrame ||
                              window.mozRequestAnimationFrame ||
                              window.webkitRequestAnimationFrame ||
                              window.msRequestAnimationFrame;

  var scrolling = false,
    mouseWheelActive = false,
    count = 0,
    mouseDelta = 0,
    $parallaxMid = $('.home__image--ghost'),
    $parallaxDeep = $('.home__image');

  function setup() {
    window.addEventListener("scroll", setScrolling, false);
    window.addEventListener("mousewheel", mouseScroll, false);
    window.addEventListener("DOMMouseScroll", mouseScroll, false);
    animationLoop();
  }

  function mouseScroll(e) {
    mouseWheelActive = true;

    // cancel the default scroll behavior
    if (e.preventDefault) {
      e.preventDefault();
    }

    // deal with different browsers calculating the delta differently
    if (e.wheelDelta) {
      mouseDelta = e.wheelDelta / 120;
    } else if (e.detail) {
      mouseDelta = -e.detail / 3;
    }
  }

  function setScrolling() {
    scrolling = true;
  }

  function getScrollPosition() {
    if (document.documentElement.scrollTop == 0) {
      return document.body.scrollTop;
    } else {
      return document.documentElement.scrollTop;
    }
  }

  function setTranslate3DTransform(element, yPosition) {
    var value = 'translate3d(0px' + ', ' + yPosition + 'px' + ', 0)';
    $(element).css('transform', value);
  }

  function animationLoop() {
    // adjust the image's position when scrolling
    if (scrolling) {
      setTranslate3DTransform($parallaxMid, getScrollPosition() / 5);
      setTranslate3DTransform($parallaxDeep, getScrollPosition() / 7);
      scrolling = false;
    }
    // scroll up or down by 10 pixels when the mousewheel is used
    if (mouseWheelActive) {
      window.scrollBy(0, -mouseDelta * 10);
      count++;
      // stop the scrolling after a few moments
      if (count > 20) {
        count = 0;
        mouseWheelActive = false;
        mouseDelta = 0;
      }
    }
    requestAnimationFrame(animationLoop);
  }
});
