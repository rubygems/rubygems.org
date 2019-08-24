$(document).on('click', '.caret', function () {
  var current = $(this)
  var gem_id = $(this).attr('data-gem_id');
  var version_id = $(this).attr('data-version');
  $.ajax({
    type: "get",
    url: "/gems/"+gem_id+"/versions/"+version_id+"/dependencies.json",
    success: function(resp) {
      renderDependencies(resp, gem_id, current)
    },
    error: function() {
      var error_message = "<ul class='deps_item--error'>Request failed. please reload the page and try again</ul>"
      current.parent().next().next().html(error_message)
    }
  });
})

function renderDependencies(resp, gem_id, current) {
  scope_display(current, gem_id, resp.run_deps, "runtime")
  scope_display(current, gem_id, resp.dev_deps, "development")
  arrow_toggler(current)
}

function arrow_toggler(current) {
  var toggler = "<span class='deps_expanded deps_expanded-down'></span>";

  current.parent().click(function() {
    var runtime_div = $(this).parent().find('div').first()
    runtime_div.toggleClass('deps_toggle');
    runtime_div.next().toggleClass('deps_toggle');
    $(this).find('span').first().toggleClass('deps_expanded-down');
  });
  current.parent().html(toggler);
}

function scope_display(current, gem_id, deps,scope) {
  if (deps.length != 0){
    var new_gems = current.parent().next().next()
    if (scope == "development") { new_gems = new_gems.next() }
    deps_display(deps, gem_id, scope, new_gems.find(".deps_scope"))
  }
}

function deps_display(deps_names, gem_id, scope, new_gems) {
  new_gems.before("<span class='scope scope--expanded'>"+scope+" :</span>");
  $.each(deps_names, function (idx,dep_details) {
    dep = dep_details[0]
    version = dep_details[1]
    req = dep_details[2]

    var link = "<span class='caret'  data-gem_id='"+dep+"' data-version='"+version+"'></span>";
    var value = "<span class='deps_item'>"+dep+" "+version+"<span class='deps_item--details'> "+req+"</span></span>";

    var toggle_link = "<span>"+link+"</span>";
    var link_to_gem = " <a href='/gems/"+dep+"/versions/"+version+"' target='_blank'>"+value+"</a>";
    var deps_run = "<div><div class='deps_scope'></div></div>"
    var deps_dev = "<div><div class='deps_scope'></div></div>"
    var deps_list = deps_run+deps_dev;
    new_gems.append("<ul class='deps'><li>"+toggle_link+link_to_gem+deps_list+"</li></ul>");
  });
  if (scope == "development"){
    new_gems.toggleClass("deps_toggle")
    new_gems.parent().find(".scope").first().removeClass("scope--expanded")
  }
}

$(document).on('click', '.scope', function () {
  $(this).toggleClass("scope--expanded")
  $(this).next().toggleClass("deps_toggle")
  $(this).next().next().toggleClass("deps_toggle")
})
