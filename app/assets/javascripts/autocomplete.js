$(function() {
  $('#home_query').autocomplete();
  $('#query').autocomplete();
});


(function($) {
  $.fn.autocomplete = function() {
    var indexNumber = -1;
    var previousForm = 'null';
    var originalForm = 'null';
    var _that = this;
    this.attr('autocomplete', 'off');
    var listName = this.attr('id') + "SuggestList";
    this.after("<ul id=" + listName + "></ul>");
    var $list = $('#' + listName);
    $list.attr('class', 'suggest-list');

    function getListLength(){
      return $list.find('li').length;
    };

    function listItemExists(){
      return getListLength();
    }

    function isNotIndexNumberOutofList(){
    return (indexNumber != -1 || indexNumber == getListLength()) ?  true: false;
    };

    function selectListItem(){
      if ( isNotIndexNumberOutofList() ){
        $list.find('li').eq(indexNumber).focusItem();
        _that.val($list.find('.selected').text());
      } else {
        _that.val(originalForm);
      };
    };

    function addDataToSuggestList(data) {
      $list.find('li').remove();
      for (var i = 0; i < data.length && i < 10; i++) {
        var newItem = $('<li>').text(data[i]);
        $(newItem).attr('class', 'menu-item');
        $list.append(newItem);
      }
      indexNumber = -1;
      $list.show();
    };

    $.fn.focusItem = function() {
      $('li').removeClass('selected');
      this.addClass('selected');
      return this;
    };

    function correctIndexNumber() {
      switch (indexNumber){
        case -2: return getListLength() - 1; break;
        case getListLength(): return -1; break;
        default: return indexNumber; break;
      };
    };

    function movePrev(){
      indexNumber--;
      indexNumber = correctIndexNumber();
    };

    function moveNext(){
      indexNumber++;
      indexNumber = correctIndexNumber(indexNumber);
    }

    function upSelected() {
      $list.find('li').removeClass('selected');
      movePrev();
      selectListItem(indexNumber);
      $list.show();
    };

    function downSelected(){
      $list.find('li').removeClass('selected');
      moveNext();
      selectListItem();
      $list.show();
    };

    this.blur(function() {
      $list.hide();
    });
    this.focus(function() {
      if (listItemExists()) {
        $list.show();
      }
    });

    function upSelect(e){
      return (e.keyCode == 38 || (e.ctrlKey && e.keyCode == 80)) ? true : false;
    };

    function downSelect(e){
      return (e.keyCode == 40 || (e.ctrlKey && e.keyCode == 78)) ? true : false;
    };

    this.keyup(function(e) {
      e.preventDefault();
      var input = $.trim($(this).val());
      if (input.length >= 2 && previousForm != input) {
        originalForm = _that.val();
        $.ajax({
          url: '/api/v1/search/autocomplete',
          type: 'GET',
          data: ('query=' + input),
          processData: false,
          contentType: false,
          dataType: 'json'
        }).done(function(data) {
          if (data.length) {
            addDataToSuggestList(data);
          } else {
            $list.hide();
          };
        });
      };
      if (upSelect(e)) {
        upSelected();
      } else if (downSelect(e)) {
        downSelected();
      };
      if (input.length < 2) {
        $list.hide();
        $list.find('li').remove();
      };
      if (!listItemExists()) {
        $list.hide();
      };
      previousForm = $.trim($(this).val());
    });

    this.parent().on({
      'mousedown': function() {
        _that.val($(this).text())
        _that.parent().submit();
      },
      'mouseenter': function() {
        $(this).focusItem();
        indexNumber = $('.selected').index();
      },
      'mouseleave': function() {
        $(this).removeClass('selected');
      }
    }, ('#' + listName + ' > .menu-item'));
  };
})(jQuery);
