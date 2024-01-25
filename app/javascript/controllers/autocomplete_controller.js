import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query suggest"]

  connect() {
    this.indexNumber = -1;
    /* remove suggest drop down if clicked anywhere on page */
    $('html').click(function(e) { $(this.suggestTarget).find('li').remove(); });
  }

  queryTargetConnected(search) {
    search.addEventListener('input', (e) => {
      var term = $.trim($(search).val());
      if (term.length >= 2) {
        console.log(term);
        $.ajax({
          url: '/api/v1/search/autocomplete',
          type: 'GET',
          data: ('query=' + term),
          processData: false,
          dataType: 'json'
        }).done((data) => {
          this.addToSuggestList(search, data);
        });
      } else {
        $(this.suggestTarget).find('li').remove();
      }
    });

    search.addEventListener('keydown', (e) => {
      if (e.keyCode == 38) {
        this.indexNumber--;
        this.focusItem(search);
      } else if (e.keyCode == 40) {
        this.indexNumber++;
        this.focusItem(search);
      };
    });
  }

  addToSuggestList(search, data) {
    $(this.suggestTarget).find('li').remove();

    for (var i = 0; i < data.length && i < 10; i++) {
      var newItem = $('<li>').text(data[i]);
      $(newItem).attr('class', 'menu-item');
      $(this.suggestTarget).append(newItem);

      /* submit the search form if li item was clicked */
      newItem.click(function() {
        $(search).val($(this).html());
        $(search).parent().submit()
      });

      newItem.hover(function () {
        $('li').removeClass('selected');
        $(this).addClass("selected");
      });
    }

    this.indexNumber = -1;
  };

  focusItem(search){
    var suggestLength = $(this.suggestTarget).find('li').length;
    if (this.indexNumber >= suggestLength) this.indexNumber = 0;
    if (this.indexNumber < 0) this.indexNumber = suggestLength - 1;

    $('li').removeClass('selected');
    $(this.suggestTarget).find('li').eq(this.indexNumber).addClass('selected');
    $(search).val($(this.suggestTarget).find('.selected').text());
  }
}
