# RubyGems.org Temporary Push Access Policy

**Status:** Working draft — not in effect

This RubyGems.org Temporary Push Access Policy is part of, and subject to the terms of, the RubyGems.org [Terms of Service](https://rubygems.org/policies/terms-of-service). It extends the Package Ownership rules in our [Acceptable Use Policy](https://rubygems.org/policies/acceptable-use).

*RubyGems.org has a first-come, first-serve policy on gem names, and ownership of a gem belongs to its publisher. For almost every gem, who can publish a release is the owner's decision and ours to stay out of. This policy exists for the rare exception.*

In rare and specific circumstances, RubyGems.org will grant a person the ability to publish a single release of a gem they do not own. We do this only when a gem the Ruby ecosystem depends on needs a release, the people maintaining its repository are ready to make one, and the existing people authorized to publish cannot be reached to arrange it.

Access is provided through an operator-issued API key for the approved release, not ownership of the gem. Publication scope and correction limits are set out below.

## When This Applies

We consider temporary push access only when a gem is important enough to the Ruby ecosystem that leaving it without releases would harm the people who use it, and only when the gem is still being maintained, meaning that people other than the owner hold merge rights on its canonical repository and are using them.

The canonical repository is the one the gem's own metadata points at, or the one its last owner-published version was built from; an unrelated fork does not qualify. Where nobody but the owner holds merge rights, the path for a community that wants the gem to continue is a fork under a new name.

The release may contain changes accepted through the repository's normal process since the relevant previous release, whether those are security fixes, fixes for defects that break the gem, ordinary bug fixes or features the maintainers have already accepted. This policy unblocks the maintainers' normal release; it does not limit the release to the smallest possible fix.

Whether a gem is important enough to qualify is a judgement the RubyGems.org team makes case by case, considering factors such as how widely the gem is depended upon and how hard it would be for its users to move to something else. We deliberately do not set a fixed threshold for that call, and we will interpret it in favor of protecting users as a whole.

For this policy, unreachable means that the relevant existing owners have not responded to the outreach for this request by its stated deadline. A historical publication or earlier contact does not by itself establish whether an owner is reachable now. We must also establish that no existing authorized publisher or relevant organization administrator can arrange the needed release through ordinary access. Operators may also consider GitHub activity and other sources as evidence when assessing the owner's availability, but a claimed response must be verified.

This policy is not a route around an owner who responds but declines a release, is not a substitute for account recovery, and is not a way to resolve disputes between owners.

## How Access Is Requested

A request for temporary push access is opened as an issue in our public log repository, [rubygems/temporary-push-access-log](https://github.com/rubygems/temporary-push-access-log), using its request template.

[Temporary push access request form](https://github.com/rubygems/temporary-push-access-log/issues/new?template=request.yml)

A request concerning an undisclosed vulnerability is instead sent privately to security@rubygems.org, and we publish the record once the advisory is out. For those private requests, the public notice and record requirements below follow this exception rather than requiring disclosure before the advisory.

## Conditions for a Grant

Temporary push access is a serious step. Before a grant takes effect, every one of the following must be true and documented in the grant record.

### We have tried to reach the existing owners

We contact all existing gem owners and any relevant organization administrators and check whether existing publishing access can resolve the request without a grant.

We make one attempt to reach each relevant contact, using the email address on their RubyGems.org account and contacting the gemspec author email separately if it is different. The notice states the proposed action and gives the recipient at least 14 days after that attempt to respond. A grant may not take effect until the response deadlines for all relevant contacts have passed.

Alongside that contact attempt, we open a public notice as an issue on the gem's canonical repository, subject to the private-security request exception above.

Where an active exploit makes waiting itself a risk to users, the 14-day response period may be shortened. Two independent RubyGems.org operators must approve that decision, under the same independence requirements as an ordinary grant, and record what was shortened, why waiting presents a risk, and what outreach was undertaken. Shortening the timetable does not waive the other grant conditions or permit overriding a verified owner refusal.

### There is a written justification

The justification states why the release is needed, why existing publishers cannot deliver it, and what the proposed release will contain.

### Two independent operators have approved the grant

Two named, independent RubyGems.org operators approve the grant's eligibility and publication scope before access is activated. They must be different people, neither may be the requester or grantee, and relevant conflicts must be disclosed. A conflicted person cannot supply an independent approval.

### The person receiving access is known and vetted

The person receiving access—the grantee—must hold merge rights on the gem's canonical repository, hold a RubyGems.org account in good standing, and be identified to Ruby Central.

The grantee must have multi-factor authentication enabled on both their RubyGems.org account and the source-host account through which they hold merge rights. By applying, the requester and grantee agree to be identified in the public record by their public account identifiers.

### The release has been independently reviewed

The release must be built from a recorded commit and contain only changes accepted through the canonical project's normal release process. Eligible sources include maintenance branches and privately reviewed security changes, not just the default branch. Its version number must follow the gem's existing convention and be chosen by its maintainers. The grantee may have authored included changes, provided those changes have been independently reviewed and accepted.

The gem's test suite must pass. A technically qualified person other than the grantee reviews both the change set and the final built gem files before publication and does not review their own contributions. Release-mechanics changes, such as the version constant, changelog and date, must be included in the final review.

One of the approving operators may also perform this technical review if qualified and independent of the contributions being reviewed. Both operator approvals remain required, and the technical review is recorded separately from approval of the grant.

The grant identifies the gem, grantee, source commit, approved version, platform builds and the exact reviewed gem files by their checksums. Any replacement or additional artifact must be reviewed and approved within the release and correction limits below; approval of one file is not approval of different bytes bearing the same name.

### Security-motivated grants include an advisory

Every security-motivated grant includes filing or confirming an advisory, for example in the Ruby Advisory Database, so the warning to users exists independently of the release itself. Undisclosed vulnerabilities follow the private request route above.

A granted release is the work of the gem's maintainers. The reviews and approvals required by this policy do not constitute endorsement by Ruby Central or a guarantee that the release is free of defects or vulnerabilities.

## Publication Scope and Duration

The operator-issued API key authorizes publication only: it gives no authority to yank releases, manage owners, transfer the gem, change publishing configuration or delegate access. It does not add the grantee as an Owner or Maintainer.

Each upload requires both the operator-issued API key and MFA verification. This applies to every approved platform build and any authorized corrective upload. Possession of the key alone is insufficient, and unrelated existing API keys do not acquire publication authority under the grant.

The grant record states when access is activated and its absolute expiry time. Activation occurs only after the required reviews and approvals. The grant expires automatically 72 hours after activation; publication or correction does not restart that clock.

A single release may include an explicitly listed set of approved platform builds for one version. Each approved artifact may be published once. The grant does not authorize additional platforms, unrelated versions or other changes simply because time remains in the window.

Publication scope, expiry and revocation must be enforced when an artifact is accepted, including across concurrent uploads. An identical retry of an already accepted artifact does not create a new publication or additional authority. An unsuccessful attempt that accepted no artifact does not consume that artifact's allowance; if the outcome is uncertain, the registry's state must be checked before retrying.

Ordinary publication authority ends when all approved artifacts have been accepted, the original deadline passes or access is revoked, whichever happens first. The grant record may remain open for audit or consideration of the corrective release described below, but an open record is not permission to publish.

### One corrective release

If publication fails in a way that requires a different artifact or version, or a published release is defective, operators may authorize one corrective follow-up release linked to the original grant.

The correction must identify the problem being addressed and satisfy the independent review and two-operator approval requirements above before its publication authority is activated. Its approved scope must be recorded. It does not authorize unrelated changes or reopen publication authority for the original artifacts.

The correction and all its approved platform builds must be published before the original grant expires. Already published artifacts cannot be overwritten; a correction may require a new version.

Operators handle any necessary yank under the applicable yank rules.

Anything beyond this one correction, or any publication after the original expiry, requires a new grant through the full process above.

## Owner Responses and Revocation

A verified reply from an existing owner pauses the request and any unused publication access while operators clarify the owner's wishes and whether ordinary publishing arrangements or account recovery can resolve the issue.

A verified refusal from an existing owner closes the request and ends any unused access, including in an emergency. A reply received after publication does not itself undo an already published release.

RubyGems.org operators may suspend or revoke remaining access on evidence of compromise, misuse, ineligibility or an owner objection, with the reason recorded.

## The Gem Owner

The gem still belongs to its existing owner or owners. A temporary push grant does not add, remove, transfer, suspend or change any ownership or ownership role, and does not create a right to future releases or permanent ownership.

Where existing owners cannot be reached, we may proceed without their consent under this policy and will notify them at their account contact addresses as soon as we are able.

Existing owners retain their ordinary rights. The Terms of Service, Acceptable Use Policy and applicable yank rules apply to them, including on whether a release made under this policy may be yanked. These releases receive no special exemption from those rules.

RubyGems.org retains its ordinary security and abuse-enforcement responsibilities after a grant ends.

## Transparency

We record each request and the decision and reasoning on its request issue, whether access is granted or refused. Refused requests remain public with the reason, subject to the private-security request exception above. There is no formal appeal, though a refused request may be resubmitted with new facts.

For a granted request, the record identifies the grantee, approving operators, technical reviewer, approved release artifacts, activation and expiry times, publication outcome, and any authorized correction or revocation.

A release published under this policy is attributed to the grantee's RubyGems.org account rather than the gem's existing owners. The operator-issued key must preserve that attribution.

## Misuse and Enforcement

If temporary push access is misused, for example to publish a release that violates our policies or that the grant did not authorize, we will revoke remaining access and yank the affected release. We may take any other enforcement action available to us, including account suspension or termination, as described in the Violations and Enforcement section of our [Acceptable Use Policy](https://rubygems.org/policies/acceptable-use).

## Questions

For questions about this policy, contact support@rubygems.org. For legal matters, contact legal@rubycentral.org.
