$(document).ready(function() {
  var divs = "#flash_success, #flash_notice, #flash_error";
  $(divs).each(function() {
    humanMsg.displayMsg($(this).text());
    return false;
  });

  if(window.location.href.search(/query=/) == -1) {
    $("#query").click(function() {
      $(this).val("");
      $(this).unbind("click");
    });
  }

  if($(".count").length > 0) {
    setInterval(function() {
      $.getJSON("/api/v1/downloads.json", function(data) {
        $(".count strong").text(number_with_delimiter(data['total']) + " downloads");
      });
    }, 5000);
  }
});

// http://kevinvaldek.com/number-with-delimiter-in-javascript
function number_with_delimiter(number, delimiter) {
  number = number + '', delimiter = delimiter || ',';
  var split = number.split('.');
  split[0] = split[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1' + delimiter);
  return split.join('.');
};
