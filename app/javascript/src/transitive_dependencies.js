import $ from "jquery";

$(document).on('click', '.deps_expanded-link', function () {
  try {
  var current = $(this);
  var gem_id = this.dataset.gemId;
  var version_id = this.dataset.version;
  const url = "/gems/"+gem_id+"/versions/"+version_id+"/dependencies.json";
  $.ajax({
    type: "get",
    url: url,
    success: function(resp) {
      renderDependencies(resp, current);
    },
    error: function() {
      var error_message = "<ul class='deps_item--error'>Request failed. please reload the page and try again</ul>";
      current.parent().next().next().html(error_message);
    }
  });
} catch (e) {
  alert(e);
}
});

function renderDependencies(resp, current) {
  scope_display(current, resp.run_html, "runtime");
  scope_display(current, resp.dev_html, "development");
  arrow_toggler(current);
}

function arrow_toggler(current) {
  var toggler = "<span class='deps_expanded arrow_toggle deps_expanded-down'></span>";
  current.parent().html(toggler);
}

function scope_display(current, deps, scope) {
  if (deps.length != 0){
    var new_gems = current.parent().next().next();
    if (scope == "development") { new_gems = new_gems.next(); }
    new_gems.find(".deps_scope").append(deps);
  }
}

$(document).on('click', '.scope', function () {
  $(this).toggleClass("scope--expanded");
  $(this).next().toggleClass("deps_toggle");
});

$(document).on('click', '.arrow_toggle', function () {
  var runtime_div = $(this).parent().next().next();
  runtime_div.toggleClass('deps_toggle');
  runtime_div.next().toggleClass('deps_toggle');
  $(this).toggleClass('deps_expanded-down');
});
