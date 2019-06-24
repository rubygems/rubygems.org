$(function(){
  $('#home_query').autocomplete({
    source:  function(request, response) {
    $.getJSON("/search/autocomplete", { query: request.term }, response);
    }
  });
});
