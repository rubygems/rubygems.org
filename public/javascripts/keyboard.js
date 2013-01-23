$(function() {

  var selectedGemIndex = -1;
  var gems = $(".gems ol li");

  var selectNextGem = function() {
    selectedGemIndex++;
    if (selectedGemIndex >= gems.length) {
      selectedGemIndex = 0;
    }
    highlightSelectedGem();
  }

  var selectPreviousGem = function() {
    selectedGemIndex--;
    if (selectedGemIndex < 0) {
      selectedGemIndex = gems.length - 1;
    }
    highlightSelectedGem();
  }

  var highlightSelectedGem = function() {
    gems.removeClass("selected");
    findSelectedGem().addClass("selected");
  }

  var visitSelectedGem = function() {
    window.location = findSelectedGem().find("a").attr("href");
  }

  var findSelectedGem = function() {
    return $(gems[selectedGemIndex]);
  }

  $(document).bind('keyup', function(event) {

    if ($(event.target).is(':input')) {
      return;
    }

    if (event.which == 83) { // s
      $('#query').focus();
    } else if (event.which == 74) { // j
      selectNextGem();
    } else if (event.which == 75) { // k
      selectPreviousGem();
    } else if (event.which == 13) { // <return>
      visitSelectedGem();
    }

  });

});
