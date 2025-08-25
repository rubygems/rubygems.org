document.addEventListener("click", function (event) {
  const trigger = event.target.closest(".deps_expanded-link");
  if (!trigger) return;
  event.preventDefault();
  try {
    const gemId = trigger.dataset.gemId;
    const versionId = trigger.dataset.version;
    const url = `/gems/${gemId}/versions/${versionId}/dependencies.json`;
    fetch(url, { method: "GET" })
      .then((response) => response.json())
      .then((resp) => {
        renderDependencies(resp, trigger);
      })
      .catch(() => {
        const error_message =
          "<ul class='deps_item--error'>Request failed. please reload the page and try again</ul>";
        const container =
          trigger.parentElement.nextElementSibling.nextElementSibling;
        if (container) container.innerHTML = error_message;
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
  const toggler =
    "<span class='deps_expanded arrow_toggle deps_expanded-down'></span>";
  const parent = current.parentElement;
  if (parent) parent.innerHTML = toggler;
}

function scope_display(current, deps, scope) {
  if (deps.length !== 0) {
    let new_gems = current.parentElement.nextElementSibling.nextElementSibling;
    if (scope === "development") {
      new_gems = new_gems.nextElementSibling;
    }
    const scopeContainer = new_gems.querySelector(".deps_scope");
    if (scopeContainer) scopeContainer.insertAdjacentHTML("beforeend", deps);
  }
}

document.addEventListener("click", function (event) {
  const el = event.target.closest(".scope");
  if (!el) return;
  el.classList.toggle("scope--expanded");
  if (el.nextElementSibling)
    el.nextElementSibling.classList.toggle("deps_toggle");
});

document.addEventListener("click", function (event) {
  const el = event.target.closest(".arrow_toggle");
  if (!el) return;
  const runtime_div = el.parentElement.nextElementSibling.nextElementSibling;
  if (runtime_div) {
    runtime_div.classList.toggle("deps_toggle");
    if (runtime_div.nextElementSibling)
      runtime_div.nextElementSibling.classList.toggle("deps_toggle");
  }
  el.classList.toggle("deps_expanded-down");
});
