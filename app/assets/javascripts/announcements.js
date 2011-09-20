function hideAnnouncement(announcement_created_at) {
  createCookie(announcement_created_at, 'hidden', 1);
  $("#announcement").parent().slideUp();
}

// http://www.quirksmode.org/js/cookies.html
function createCookie(name,value,days) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();
  }
  else var expires = "";
  document.cookie = name+"="+value+expires+"; path=/";
}
