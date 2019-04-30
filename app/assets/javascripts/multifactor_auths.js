if($("#recovery-code-list").length){
  window.addEventListener("beforeunload", function (e) {
    e.preventDefault();
    e.returnValue = '';
  });
}
