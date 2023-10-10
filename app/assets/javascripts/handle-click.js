export function handleClick(
  event,
  nav,
  removeNavExpandedClass,
  addNavExpandedClass
) {
  var isMobileNavExpanded = nav.popUp.hasClass(nav.expandedClass);

  event.preventDefault();

  if (isMobileNavExpanded) {
    removeNavExpandedClass();
  } else {
    addNavExpandedClass();
  }
}
