$(function() {
  if ($('#home_query').length){
    autocomplete($('#home_query'));
    var suggest = $('#suggest-home');
  } else {
    autocomplete($('#query'));
    var suggest = $('#suggest');
  }

  var indexNumber = -1;

  function autocomplete(search) {
    search.bind('input', function(e) {
      var term = $.trim($(search).val());
      if (term.length >= 2) {
        $.ajax({
          url: '/api/v1/search/autocomplete',
          type: 'GET',
          data: ('query=' + term),
          processData: false,
          dataType: 'json'
        }).done(function(data) {
          addToSuggestList(search, data);
        });
      } else {
        suggest.find('li').remove();
      }
    });

    search.keydown(function(e) {
      if (e.keyCode == 38) {
        indexNumber--;
        focusItem(search);
      } else if (e.keyCode == 40) {
        indexNumber++;
        focusItem(search);
      };
    });
  };

  function addToSuggestList(search, data) {
    suggest.find('li').remove();

    for (var i = 0; i < data.length && i < 10; i++) {
      var newItem = $('<li>').text(data[i]);
      $(newItem).attr('class', 'menu-item');
      suggest.append(newItem);

      /* submit the search form if li item was clicked */
      newItem.click(function() {
        search.val($(this).html());
        search.parent().submit()
      });

      newItem.hover(function () {
        $('li').removeClass('selected');
        $(this).addClass("selected");
      });
    }

    indexNumber = -1;
  };

  function focusItem(search){
    var suggestLength = suggest.find('li').length;
    if (indexNumber >= suggestLength) indexNumber = 0;
    if (indexNumber < 0) indexNumber = suggestLength - 1;

    $('li').removeClass('selected');
    suggest.find('li').eq(indexNumber).addClass('selected');
    search.val(suggest.find('.selected').text());
  };

  /* remove suggest drop down if clicked anywhere on page */
  $('html').click(function(e) { suggest.find('li').remove(); });
});
