# About cards

Self-hosting usually happens alone. Someone puts a few apps on a box in the garage, gets them talking to each other, and puts them online. It works, and nobody else ever sees how. The next person starts again from nothing.

Cards are for the moment after it works. A card is a setup someone is happy with, written down so that anyone can reproduce it on their own machine.

## Self-hosting is social

A setup in a garage can serve more than its owner. It can run the site for a club, the tools for a team, or the photos for a family. Edgible puts each app on a public hostname, and each hostname has its own auth mode: open to anyone, behind your organization's sign-in, or behind an API key. So the people you host for use what you run, on your hardware.

Cards add the other half: the people you share with. You share what worked. Someone else runs it, changes it to suit them, and shares their version back. A private hobby becomes something people build on together.

## Solutions, not ports

Putting one port on the internet is the easy part. The hard part, and the useful part, is the whole pattern:

- which apps work together, and how they reach each other
- which hostname is open, and which needs a sign-in or a key
- which apps share a machine, and which belong on another one
- how to check it works, and how to take it down again

A card records that pattern. The website card, for example, is not just a web server. It is the site, the editor for its pages, the analytics, and a monitor that can run on a second machine, each with the right auth mode.

## Cards, not a catalog

A catalog is a promise that every app in it works, is kept up to date, and is supported. Cards make a smaller promise, so they can stay honest:

- **A card belongs to the person who wrote it.** It is a record of what worked for them. The author decides how it is built, such as which image versions it pins.
- **An app belongs to its own project.** A card shows how to get each app running and reachable, then links to the app's own docs for the rest. It does not copy them.
- **Edgible looks after the format and the tools.** The shape every card has, and the checks that keep it that shape.

## Predictable on purpose

Every card reads the same way, so once you have used one, you can use them all:

- **The same five headings:** Why, What, How, Verify, and Tear down.
- **The same steps:** Fetch, edit `card.env`, Check, Start, and Publish.
- **The same names:** `<APP>_PORT` for each port, `DEVICE` for the machine, and `ORG_LABEL` for the hostnames. The [conventions table](README.md#publish-a-card) lists them all.
- **Nothing of yours inside:** a card leaves out device names, hostnames, organization ids, and passwords. You fill those in on your own machine.

## Checks you can run

A card says how to check it, with commands rather than opinions:

- **Before you start,** `check-env.py` looks at your machine for anything the card would collide with: a port, a name, a leftover volume, an app that already exists. It prints the fix for each one as lines you can paste.
- **After you publish,** Verify checks that each hostname answers the way its auth mode says.
- **When you are done,** Tear down removes it in the right order, and copies the data before it deletes it.

Because every card has the same steps, anyone can repeat what the author did and see the same result.

## Take part

- **Use a card.** Pick one from the [list](README.md), and follow its README.
- **Adapt one.** Change a card to suit you, and share it as a variant with a name that says how it differs, such as `n8n-sqlite`.
- **Share your own.** When a setup of yours works, write it down as a card. [Publish a card](README.md#publish-a-card) says how.
