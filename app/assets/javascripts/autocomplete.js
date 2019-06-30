/*
$(function(){
  $('#home_query').autocomplete({
    source:  function(request, response) {
    $.getJSON("/search/autocomplete", { query: request.term }, response);
    }
  });
});
*/


$(document).on('keyup', '#home_query', function(e){
  var result = $('<ul>').addClass('suggest-list');
  e.preventDefault();
  var input = $.trim($(this).val());
  if (input.length >=2){
    $.ajax({
      url: '/api/v1/search/autocomplete',
      type: 'GET',
      data: ('query=' + input),
      processData: false,
      contentType: false,
      dataType: 'json'
    }).done(function(data){
      for(var i = 0; i < data.length; i++){
        var newLi = $('<li>').text(data[i]);
        result.append(newLi);
      }
      $('#home_query').append(result);
    });
  }else{
    data = nil;
  }
});
