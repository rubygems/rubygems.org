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

`ReservedPrefixValidator` runs on `Rubygem#name` for new gems, renames, and
takeovers, and defers to `PrefixReservation#permitted?`:

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
- **Takeover of an abandoned gem**: rejected. A push can take over an
  existing gem that has no indexed versions and isn't protected (see
  `Rubygem#pushable?`). `Rubygem#taken_over_by_pusher?` runs the validator
  for these pushes. Takeovers ignore `rubygems_organization` metadata, so
  even an admin of the reserving organization can't claim the gem this way;
  it needs a rubygems.org admin.

Owners of gems that existed before the reservation can keep pushing versions.

When a push is rejected, the error names the organization. For a new gem it
also gives the metadata line above.

## Known issue: pending trusted publishers are checked more loosely than pushes

`OIDC::PendingTrustedPublisher#reserved_prefix?` lets **any confirmed member**
of the reserving organization register a pending trusted publisher for a name
under the prefix. The first push from that publisher is checked against the
stricter push rule, so it succeeds only when:

1. the gemspec sets `rubygems_organization` to the reserving organization, and
2. the user who registered the pending publisher is an admin or owner of that
   organization.

This lets a user set up a pending publisher that can never push:

- A maintainer or plain member registers a pending publisher for
  `acme-widgets`. Registration succeeds, but every push fails the
  `add_gem?` check with "You do not have permission to add a gem to
  organization 'acme-corp'."
- An admin registers a pending publisher but the gemspec leaves out
  `rubygems_organization`. Every push fails with the reserved prefix error.

In both cases the user only finds out when the workflow first runs, not when
they register the publisher.

Possible fixes:

- Require `add_gem?` on the reserving organization when registering a pending
  publisher for a name under the prefix, so registration and push agree on
  the role.
- Record the organization on the pending publisher at registration, and
  assign the gem to it on the first push, so the gemspec metadata isn't
  needed.
