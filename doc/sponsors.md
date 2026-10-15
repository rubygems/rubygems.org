# Sponsor management and rollout

## Contract

Each sponsor has **one category**: Infrastructure, Open Source, or Supporter Plus.
The ambiguous "multiple tiers" requirement is interpreted as category options,
not simultaneous memberships. There is no future-tier placeholder. Ruby Central
is an ordinary record, initially categorized as Open Source; administrators can
change or remove it like any other sponsor. The supporters page is unchanged.

Anonymity and footer visibility are independent. An anonymous sponsor may retain
its internal name, URL, logo and footer preference, but the public footer and logo
endpoint always exclude it. Turning anonymity off restores its footer preference.
Public sponsors require a name, HTTP(S) URL and logo. Positions are nonnegative
integers; gaps and ties are allowed, with ties ordered by ID across all categories.

Logos must be preoptimized transparent PNG/WebP, at most 256 KB. The footer uses
the alpha channel as a monochrome CSS mask, inheriting its light/dark text color;
opaque backgrounds become solid squares. No image processing runs on the server.
SVG uploads are rejected, and Rails' SVG protections are not relaxed.

Only rubygems-org administrators can manage sponsors. Avo create/update requires
the existing audit comment; the bulk footer-visibility and category actions also
require a comment. Replace a logo through the audited edit form rather than deleting it.
Rails' storage routes are disabled; Avo's direct-upload and attachment-upload APIs
return 404. Avo previews/downloads use the same visibility-checked read endpoint,
with authenticated rubygems-org administrators allowed to inspect private logos.
It proxies bytes with `private, no-store`, never redirecting to reusable S3 URLs.
Existing browser copies cannot be revoked, and previously public names in cached
HTML remain subject to the page's existing cache lifetime.

## Ordering investigation (Avo 3.32.4)

[Avo's v3 documentation](https://docs.avohq.io/3.0/records-reordering.html#reorder-using-drag-and-drop)
documents **native Pro drag-and-drop**, Beta and opt-in via `drag_and_drop: true`
and `insert_at`. This is separate from higher/lower/top/bottom buttons.
The [3.32.4 row template](https://github.com/avo-hq/avo/blob/v3.32.4/app/components/avo/index/table_row_component.html.erb)
has `drag_reorder_item_data_attributes` hooks, and the
[3.32.4 safelist](https://github.com/avo-hq/avo/blob/v3.32.4/scripts/export-tailwind-safelist.js)
explicitly identifies Pro drag-and-drop classes. The optional Advanced 3.32.4
dependency includes Pro. Community does not provide this implementation.

The paid package server returned 403 in the implementation orb, so paid runtime
behavior and its audit integration could not be inspected or exercised. This
implementation deliberately uses audited editable manual positions, not a custom
drag-and-drop UI or unverified ordering callbacks that bypass the mandatory audit
comment. Do not describe native support as absent. Enabling it later requires
access to the paid gems and verified authorization/auditing for each reorder.

## Deploy requirements (no infrastructure was provisioned)

1. Choose a **private dedicated bucket** and set `SPONSOR_LOGOS_BUCKET` and
   `SPONSOR_LOGOS_REGION` on both web and job processes. Staging/production use the
   `sponsors` S3 service; development/test use local disk. Use the AWS SDK's normal
   credential chain (prefer an IAM role), never committed keys. Grant only the
   required object read/write/delete permissions; block public bucket access.
   Configure lifecycle/backups/retention with the infrastructure owner. No public
   S3 ACL, CORS/direct-upload setup or CSP relaxation is needed.
2. Deploy the code and both migrations, keeping the **`sponsor_footer` Flipper
   flag disabled**. The existing sprite footer remains visible during rollout.
   Install the existing optional Avo Advanced gems/license for production as usual.
3. Run `Maintenance::SeedFooterSponsorsTask` through the existing audited
   maintenance-task UI. Its seven PNGs are raster exports of the existing sprite
   symbols, with original URLs/order. The task skips existing names on rerun and
   does not overwrite administrator edits. Review any preexisting same-name
   records before enabling the flag. Ensure the job image includes these assets.
   Storage uploads occur after the record commits; if an upload fails, repair the
   missing logo through the audited edit form before enabling the flag. A rerun
   deliberately does not overwrite existing records.
4. Verify all seven records and their stored logos, and review the footer in
   light/dark mode and on mobile. Enable `sponsor_footer` globally only after that
   check. From that point every footer sponsor, including Ruby Central, is managed
   exclusively through records. Roll back by disabling the flag if necessary;
   the legacy footer is only a rollout fallback and will not reflect admin edits.

Do not silently enable the flag in a migration or task. The seed writes S3 objects
and shared data, so running it in staging/production requires rollout authorization.
Once the rollout is established, remove the fallback in a separate cleanup.

### Seed asset provenance

The seven 240×240 transparent PNGs in `app/assets/images/sponsors` are derived from
the corresponding symbols in `app/assets/images/icons.svg`, not external logos.
Each symbol's children and viewBox were wrapped in a standalone SVG with width
and height 240, then rasterized using `rsvg-convert` 2.54.7. This is an offline
asset-generation step, not a runtime dependency.
