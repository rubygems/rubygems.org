# Supporter logos

How to add them to the site footer.

The footer is rendered by `FooterComponent`
(`app/views/components/footer_component.rb`). 

We use a full color SVG or PNG (or whatever) logo on the Supporters page and a monochrome logo in the footer that is recolored depending on the light/dark color scheme. The footer logos are placed in fixed-size boxes and we alter the svg aspect ratio to match for consistent sizing.

## What to ask supporters for

- **A full-colour logo for the Supporters page** (`/supporters`), as an SVG or PNG. This page shows logos in their brand colors on light tiles at about 210×110px.
  - **SVG** is preferred. The same rules as above apply, except for colour: vector shapes only, text converted to outlines, cropped tight.
  - **PNG** is fine if they don't have an SVG. It needs a transparent background and should be cropped tight, at least **840px wide**, so it stays sharp on high-resolution screens.
  - A horizontal layout is still best, but this page has more room, so a stacked/square version also works.
- **Brand guidelines:** required clear space, minimum size, whether a one-colour version is allowed, and the URL the logo should link to. (We may be outside of Brand guidelines by doing a recoloring of their logo)
- ** Footer SVG ** - See below

### Footer SVG preferences

- **Format:** an SVG made only of vector shapes. No PNG or JPG embedded inside
- **Colour:** a one-colour version, solid white or solid black. We recolour it
  for light and dark mode, so gradients or multiple colours get flattened
  anyway.
- **Layout:** a horizontal logo renders better at different sizes. We could use the icon and the name side by side.
  Stacked logos shrink to a small square and the name becomes unreadable.
- **No small extra text:** no taglines, "by …" lines or ® marks that become
  unreadable when small.
- **Render Size:** about 32–36px tall by about 80px wide on desktop to as narrow as about 80px wide on phones. A
  width-to-height ratio between about **2:1 and 5:1** works best.
- **Cropped tight:** no padding or blank space around the logo. The footer adds its own spacing, and padding makes a logo look smaller than its neighbours.
- **Text converted to outlines:** no live fonts.
- **Simple file:** no masks, clipping paths, filters, effects or hidden layers.


## Adding a logo to the footer

1. **Make the SVG one colour.** Remove `fill` attributes (or set them to `currentColor`) so the footer's `fill-current` colours the logo. Delete any `<image>`, `<mask>`, `<pattern>` or `<clipPath>` elements. If a shape is drawn in a background colour to look like a hole (Shopify's "S" did this), merge it into the shape around it and use `fill-rule="evenodd"`.
2. **Add a symbol to `icons.svg`.** Wrap the paths in `<symbol id="<name>-footer" viewBox="...">`. The `viewBox` should fit the drawn shape with no padding. Size units don't matter: the footer sets each logo's height and figures out the width from the `viewBox` proportions. Only the proportions and any padding affect how big the logo looks. To measure a file that isn't cropped tightly, open it in a browser and call `getBBox()` on the paths.
3. **Add the supporter to `FooterComponent::TIERS`** in the right tier. Use a `view_box` of `"0 0 <width> <height>"`, taking the width and height from the symbol's `viewBox`. The origin must be `0 0`. Every supporter needs an `icon` and a `view_box`: new supporters are expected to submit a logo when they join, so there's no text fallback.
4. **Run the tests** in `test/components/footer_component_test.rb`. Test checks every icon exists in the sprite and compares the view box size with the actual svg to catch mistakes.
5. **Check it in a browser** at desktop and phone widths, in both light and dark mode. The logo should be readable and not overflow its box.
