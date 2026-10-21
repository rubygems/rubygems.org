# Prefix reservations

A `PrefixReservation` reserves a gem name prefix for an organization. A
rubygems.org admin creates one in Avo. For example, `acme` reserves
`acme-widgets`, `acme_widgets`, and `acmewidgets`. Matching ignores case and
treats `_` literally.

Reservations can't overlap: if `acme` is reserved, neither `acme-corp` nor
`acm` can be, even for the same organization. That way every gem name falls
under at most one reservation. A reservation without an organization, or
whose organization was deleted, still blocks overlapping prefixes until it is
destroyed.

## Who can create a gem under a reserved prefix

`ReservedPrefixValidator` runs on `Rubygem#name` for new gems and renames, and
defers to `PrefixReservation#permitted?`:

- **New gem**: the push must claim the reserving organization through gemspec
  metadata, and the claiming user must be a confirmed member:

  ```ruby
  spec.metadata["rubygems_organization"] = "acme-corp"
  ```

  `Pusher` only records the claim once `OrganizationPolicy#add_gem?` allows
  it, so in practice the user must be an organization **admin** or owner. For
  a trusted publisher push, the claiming user is the user who registered the
  pending trusted publisher.
- **Rename**: allowed only when the gem already belongs to the reserving
  organization.
- **No organization, or a deleted one**: the prefix stays reserved, and
  nobody can create a gem under it until the reservation is destroyed.
  `organization_id` is nullable, so an admin can leave it blank to block a
  prefix outright.
- **Takeover of an abandoned gem**: rejected. A push can normally take over
  an existing gem that has no indexed versions and isn't protected, but
  `Rubygem#pushable?` is false for a name under a reserved prefix, so the
  push fails with the usual "You do not have permission to push to this gem"
  error. Takeovers ignore `rubygems_organization` metadata, so even an admin
  of the reserving organization can't claim the gem this way; it needs a
  rubygems.org admin.

Owners of gems that existed before the reservation can keep pushing versions.

When a new gem is rejected, the error names the organization and gives the
metadata line above.

## Pending trusted publishers

`OIDC::PendingTrustedPublisher#reserved_prefix?` uses the same
`OrganizationPolicy#add_gem?` check as a push, so only an admin or owner of
the reserving organization can register a pending trusted publisher for a
name under the prefix.

Registration can't see the gemspec, though. If the gemspec leaves out
`rubygems_organization`, the first push still fails with the reserved prefix
error. Recording the organization on the pending publisher at registration
would close that gap.
