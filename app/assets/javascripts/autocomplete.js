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
  e.preventDefault();
  var input = $.trim($(this).val());
  $.ajax({
    url: '/search/autocomplete',
    type: 'GET',
    data: ('query=' + input),
    processData: false,
    contentType: false,
    dataType: 'json'
  })
});
