# Security Engineers in Residence: FAQ

[Ruby Central](http://rubycentral.org) has been awarded a grant from [Alpha-Omega](https://alpha-omega.dev/) to fund a team of Security Engineers in Residence for the Ruby ecosystem. The idea behind the program is a simple one: every report that reaches a maintainer should be the work of a person who understood the gem first. AI helps the team find candidate vulnerabilities faster, but nothing reaches you until a person has confirmed the issue is real, worked out what it means in practice, and decided it is worth your time.

This FAQ covers what the program is, how the team works, what to expect if we find something in your gem, what it means if you only depend on gems, and how to tell a real report from the noise. If something here is unclear or you think it could work better, we want to hear it. You can always reach us at [gem-security@rubygems.org](mailto:gem-security@rubygems.org).

## About the program

### What is the Security Engineers in Residence program?

It is a funded team that looks for real vulnerabilities in the gems the community depends on most, confirms them, and brings maintainers reports that are worth their time. The work is scanning, verification, severity assessment, and coordinated disclosure, meaning we tell a maintainer privately and give them time to fix an issue before anything becomes public. The core principle is that nothing reaches a maintainer until a person has confirmed the issue is real and worked out what it means in practice.

### Who funds it and who runs it?

Alpha-Omega funds it through a grant. Ruby Central runs it. Ruby Central is the nonprofit that stewards RubyGems.org, RubyGems, and Bundler.

### Why does this program exist?

Automated tooling, much of it built on large language models, has made finding candidate vulnerabilities cheap and fast. Acting on a raw signal responsibly is not cheap. Someone has to confirm the issue is real, assess its impact, and decide whether it warrants a maintainer's attention. That work falls on people, and people are the scarce part.

The same tooling has produced a rising volume of low-quality, AI-generated reports that waste maintainer time and bury the issues that matter. This program is built to be the opposite of that.

### What does the team actually do?

Four things. We scan prioritized Ruby projects for vulnerabilities. We verify what we find so maintainers do not receive noise. We assess real-world severity using Ruby-specific deployment context rather than a generic score. And we coordinate disclosure directly with maintainers, then publish the confirmed finding so the rest of the ecosystem is protected. Where it helps, the team also produces Ruby-specific security guidance maintainers can apply on their own.

### How is this different from the AI-generated reports maintainers already get too many of?

The difference is the human bar. AI is used to find candidates faster, but a person confirms the finding is real, assesses its impact, and decides it is worth sending before anything goes out. If it does not clear that bar, it does not get sent. We are not trying to maximise the number of reports we send. A report only leaves the team when a person is prepared to put their name to it.

Our first report set that bar: a ReDoS vulnerability in Nokogiri's CSS query tokenizer, meaning a crafted input that makes a regular expression hang and can stall a server. The maintainers validated and fixed it. We confirmed it before we sent it, sent it privately, and left the people who maintain the gem to decide what to do from there.

### Is this about CVE counts or bounties?

No. There are no bounties and no vanity metrics. The program answers to the health of the ecosystem, not to a metric or a paying customer. The people doing the work depend on these libraries too.

## What is in scope

### What gems does the team look at?

Ruby's core infrastructure, meaning RubyGems and Bundler, and the most widely depended-on gems. We work down a prioritized list rather than scanning everything at once, because verification is the expensive part and we would rather do it well on the gems that matter most.

### How is that list decided?

Gems are ranked by a formula:

Priority \= Criticality × (1 − Risk) × Maintenance

**Criticality \[0-1\]** is how much the ecosystem depends on the gem: downloads, direct and transitive reverse-dependencies, closeness to Rails, age, and releases.

**Risk \[0-1\]** is how dangerous it looks now: known vulnerabilities, category blast radius, supply-chain signals, and publishing hygiene. It is stored as 1 \= safe, so (1 − Risk) flips it to push risky gems up.

**Maintenance \[0.925-1.250\]** is a multiplier rather than a fixed score, covering release cadence, repo liveness, bus factor, and contributor activity. Abandoned gems raise priority (up to 1.25x), healthy ones marginally lower it (down to 0.925x).

The data feeding this comes primarily from RubyGems.org and is recomputed periodically as downloads, releases, and dependencies change.

### Can I find out if my gem is on the list, or put it forward?

You do not have to wait to be contacted. If you maintain a gem and want it reviewed, reach out at [gem-security@rubygems.org](mailto:gem-security@rubygems.org) and we will work with you. The ranked list is how we prioritize our own scanning, not a queue you need to be at the top of to get help.

## If you depend on gems but do not maintain one

### What does this program do for me?

Most of the program runs behind the scenes between the team and maintainers, but the output is meant for you. When we confirm a vulnerability and a fix is available, we publish it as a GitHub Security Advisory by default. That flows into the GitHub Advisory Database and OSV, so tools you may already run, such as Dependabot, bundler-audit, and other OSV-based scanners, pick it up against your `Gemfile.lock` without you doing anything. Where a finding warrants a CVE, we coordinate that too.

The honest limit is coverage. We are focused on core infrastructure and the most depended-on gems, and we are scaling into the next top 1000\. The long tail of a typical lockfile is not covered yet. We would rather tell you that plainly than imply blanket protection we cannot deliver.

## If the team finds something in your gem

### What happens first?

You get a verified report from a person who has already done the work to confirm it, not a raw tool dump. We reach out privately, explain what we found, and coordinate disclosure with you directly. From that first contact, the timeline and the pace are things we work out with you.

### How will the details reach me?

By default we open a private GitHub Security Advisory on your repository, which keeps the vulnerability details and any proof-of-concept out of public view while we work with you. If your gem is not on GitHub, or you would rather use another channel, we send the details over GPG-encrypted email instead. We will not put working exploit details in plain email.

### What does a report actually look like?

A report describes the vulnerability in plain terms, explains how it can be triggered, and gives you what you need to reproduce it. It includes a severity assessment grounded in how the gem is actually deployed in Ruby applications, not just a generic score, so you can judge how much it matters in practice. Where we can, we include a suggested fix or a direction for one. The goal is that you can act on it without having to redo the work of confirming it.

### What is expected of me as a maintainer?

We ask that you acknowledge the report within about two weeks so we know it reached you, and then work with us at whatever pace fits your project. There is no penalty for being slow, and there is no expectation that you drop everything. Most maintainers are volunteers, and we build the process around that rather than against it.

### What is the disclosure timeline?

We work to a 90-day coordinated disclosure window as an upper limit, but we treat it as a guide rather than a deadline to hold over you. As long as there is good-faith progress, we will keep working with you. If you need more time, tell us. The window exists so that a confirmed, serious vulnerability does not sit unaddressed indefinitely, not to force a release before you are ready.

### What gets published, and when?

Once a fix is available, we publish the confirmed finding as a GitHub Security Advisory, coordinated with you, so that people who depend on your gem learn they need to upgrade. That is the normal, intended end of the process, not a punishment. It is how a fix actually protects the ecosystem rather than just your repository. We agree the timing with you, and where a CVE is warranted, the team coordinates that assignment with you as well. You stay in the loop, and nothing is published in a way that surprises you.

### What if I disagree that the finding is real, or I cannot get to it?

If you disagree, tell us. Part of the team's job is to be wrong gracefully. We would rather you push back and we recheck than ship a fix for something that is not actually a problem. If we agree it is real but differ on how serious it is, we will show you the reasoning behind our severity assessment and work it through with you rather than overriding you.

If a confirmed, serious issue goes unanswered, we keep trying to reach you through good-faith contact over the disclosure window. Publishing without you fully on board is a last resort, and the bar for it is a genuine, verified risk to people who depend on the gem. When it comes to that, the decision is made together by the Ruby Central staff leading the program, not by a single engineer, and we give you clear notice before anything goes public so you are never blindsided.

## Verifying that outreach is legitimate

### How do I know a reach out from the team is real?

Three things to check.

* All emails come from an `@rubygems.org` account and are DKIM signed, which is a standard cryptographic signature your email provider verifies automatically. A spoofed sender address will usually be flagged by your provider as failing that check.

* Everyone on the team is a member of the [RubyGems GitHub organization](https://github.com/rubygems/). The current list of handles is kept on the program page; at the time of writing they are `@dkw-oss`, `@colby-swandale`, `@p-linnane`, `@halogenandtoast`, and `@mensfeld`.

* If a team member has signed a communication to you, their public key is published under their GitHub handle. For example, Colby's key is at `https://github.com/colby-swandale.gpg`.

You do not need special tooling to stay safe here. If anything about an approach feels off, do not act on the message itself. Email us directly at [gem-security@rubygems.org](mailto:gem-security@rubygems.org) and ask before you respond.

### What will the team never ask me to do?

Knowing the warning signs is as useful as knowing the genuine ones. We will never ask you to click through to a login page, run a script or command we send you, install software, hand over passwords, API keys, or tokens, or act on an artificial deadline. A real report gives you information and time. If a message claiming to be from the program does any of those things, treat it as suspicious and check with us first.

## Who is on the team

The hands-on scanning, verification, and disclosure is led by [Dushan Karovich-Wynne](https://github.com/dkw-oss), Ruby Central's Security Engineer, along with [Colby Swandale](https://www.linkedin.com/in/colby-swandale/), Ruby Central's Technical Lead, and [Marty Haught](https://www.linkedin.com/in/martyhaught/), Ruby Central's Director of Open Source.

They are joined by security consultants [Matt Mongeau](https://www.linkedin.com/in/mattmongeau/) and [Patrick Linnane](https://www.linkedin.com/in/patrick916/), by Ruby supply chain researcher [Maciej Mensfeld](https://www.linkedin.com/in/maciejmensfeld/), and by [Mike Dalessio](https://mike.daless.io) as the Rails Security representative, who makes sure findings in Rails and the code beneath it reach Rails Core quickly. The team also draws on [Sutou Kouhei (@kou)](https://github.com/kou) for the Ruby Core perspective and [Andrew Nesbitt](https://nesbitt.io/) for years of work on the structure and security of package ecosystems.

That mix is what lets the team judge whether a finding is real, and what it means in practice, before it ever reaches you.

## Getting involved

### Can I put my gem forward for review?

Yes. You do not have to wait to be contacted. Reach out at [gem-security@rubygems.org](mailto:gem-security@rubygems.org).

### I have a security finding in a rubygem. Can I bring it to the team?

Yes. The team will work it through with you and act as an intermediary with maintainers where that helps. Reach out at [gem-security@rubygems.org](mailto:gem-security@rubygems.org). For sensitive details, you can encrypt your report to our public key, printed at the end of this document.

### Where is the program now?

The first several engagements are deliberately small while the team proves the workflow. The Nokogiri report mentioned above was the first of them, and the reason to start there is to pressure-test how we scan, verify, and disclose before we widen the work. The aim is to turn what we learn into a repeatable process, and we are actively scaling into the next top 1000 gems as ranked above. We would rather earn trust with a process that works than promise broad coverage we cannot responsibly deliver yet.

### How do I get in touch?

If you have feedback that would make this work better, the team wants to hear it. Reach out at [gem-security@rubygems.org](mailto:gem-security@rubygems.org).

## Our public key

If you are sending sensitive details, you can encrypt them to the program's key for `gem-security@rubygems.org`. Verify the fingerprint before you trust the key.

Fingerprint: `1595 58E3 5BCC F820 A48D DB7C D170 F9A9 E4FB 3D7A`

    -----BEGIN PGP PUBLIC KEY BLOCK-----
    mDMEakSeIxYJKwYBBAHaRw8BAQdAgon28ATckQflRl3HMSueflynzkCbhVWyYws3
    0LSVWwW0LUdlbSBTZWN1cml0eSBUZWFtIDxnZW0tc2VjdXJpdHlAcnVieWdlbXMu
    b3JnPoi1BBMWCgBdFiEEFZVY41vM+CCkjdt80XD5qeT7PXoFAmpEniMbFIAAAAAA
    BAAObWFudTIsMi41KzEuMTIsMCwzAhsDBQkJZgGABQsJCAcCAiICBhUKCQgLAgQW
    AgMBAh4HAheAAAoJENFw+ank+z16mqEBAKUAVEp91yS8TKgej4zNTbR0775tApw3
    0hgHzZhOT9uwAQCGMwsTQZKAc1nVCd6zOVZyIITiBOW+U7h+iw5TJf5gALg4BGpE
    niMSCisGAQQBl1UBBQEBB0DrSXx4/cnfyT45TvH7RdUULWfObtUaM6u6jK0GXCiR
    YgMBCAeImgQYFgoAQhYhBBWVWONbzPggpI3bfNFw+ank+z16BQJqRJ4jGxSAAAAA
    AAQADm1hbnUyLDIuNSsxLjEyLDAsMwIbDAUJCWYBgAAKCRDRcPmp5Ps9empZAP0c
    qU2biehkJVsoxZNP6Dinrtj6nw8PLc+GJKOBQIZ21QD/TJxvzMxRQ4Yj6qieDzxo
    wsWjGJ/e0S55GxXIOsIzxA0=
    =UwOo
    -----END PGP PUBLIC KEY BLOCK-----
