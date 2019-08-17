$(document).on('click', '.caret', function () {
  var gem_id = $(this).attr('data-gem_id');
  var ver_id = $(this).attr('data-ver');
  $.ajax({
    type: "get",
    url: "/gems/"+gem_id+"/versions/"+ver_id+"/transitive_dependencies.json",
    success: function(resp) {
      ajaxDepActions(resp,gem_id)
    }
  });
})

function ajaxDepActions(resp,gem_id) {

  // when we have gems like http_parser.rb, we need to replace . with \. to access any ids with the name
  gem_id = gem_id.replace(/\./, "\\.")

  var all_deps = $('.deps_item').map(function() {
    return $(this).attr('data-gem_name');
  }).get();

  if (resp.run_deps.length != 0){
    $("#"+gem_id+'runtime').find(".deps_scope").before("<span class='scope scope--expanded'>Runtime :</span>");
    deps_display(resp.run_deps,gem_id,all_deps,"runtime")
  }

  if (resp.dev_deps.length != 0){
    $("#"+gem_id+'development').find(".deps_scope").before("<span class='scope'>Development :</span>");
    deps_display(resp.dev_deps,gem_id,all_deps,"development")
  }

  var toggler = "<span class='deps_expanded deps_expanded-down'></span>";
  $('#'+gem_id+'-toggle').html(toggler);
  $('#'+gem_id+'-toggle').click(function() {
    $(this).parent().parent().find('div').first().toggleClass('deps_toggle');
    $(this).parent().parent().find('div').first().next().toggleClass('deps_toggle');
    $(this).find('span').first().toggleClass('deps_expanded-down');
  });

  $('#'+gem_id+'-title').addClass('deps_item--title')
  $('.deps_item--duplicate').css("padding", "20")
}

function deps_display(deps_names,gem_id,all_deps,scope) {
  var new_gems = $("#"+gem_id+scope).find(".deps_scope")
  var duplicate_gems = $("#"+gem_id+scope).find(".dup_scope")
  $.each(deps_names, function (idx,dep_details) {
    dep = dep_details[0]
    ver_num = dep_details[1]
    req = dep_details[2]
    if(all_deps.includes(dep)) {
      var value = "<li><span class='deps_item deps_item--dup'>"+dep+" "+ver_num+"<span class='deps_item--details'> "+req+"</span></span></li>";
      var link_to_gem = "<a href='/gems/"+dep+"/versions/"+ver_num+"' target='_blank'>"+value+"</a>";
      duplicate_gems.append(link_to_gem);
    }
    else {
      var link = "<span class='caret'  data-gem_id='"+dep+"' data-ver='"+ver_num+"'></span>";
      var value = "<span data-gem_name='"+dep+"' id='"+dep+"-title' class='deps_item'>"+dep+" "+ver_num+"<span class='deps_item--details'> "+req+"</span></span>";

      var toggle_link = "<span id='"+dep+"-toggle'>"+link+"</span>";
      var link_to_gem = " <a href='/gems/"+dep+"/versions/"+ver_num+"' target='_blank'>"+value+"</a>";
      var deps_org = "<div id='"+dep+"runtime'><div class='deps_scope'></div><div class='dup_scope'></div></div>"
      var deps_dup = "<div id='"+dep+"development'>\n<div class='deps_scope'></div>\n<div class='dup_scope'></div></div>"
      var deps_list = deps_org+deps_dup;
      new_gems.append("<ul class='deps'><li>"+toggle_link+link_to_gem+deps_list+"</li></ul>");
    }
  });
  if (scope == "development"){
    new_gems.toggleClass("deps_toggle")
    duplicate_gems.toggleClass("deps_toggle")
  }
}

$(document).on('click', '.scope', function () {
  $(this).toggleClass("scope--expanded")
  $(this).next().toggleClass("deps_toggle")
  $(this).next().next().toggleClass("deps_toggle")
})
