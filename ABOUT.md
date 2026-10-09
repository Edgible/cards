# About cards

Say you want a website. You'll probably also want a decent CMS to edit it, some analytics, and something that tells you when it falls over. The default answer these days is a subscription for each of those, with your content and your visitors' data sitting on someone else's servers.

We think there's a better default: run it yourself. Your data stays on a machine you own, and nothing sensitive has to leave the building. Open-source tools on your own hardware don't change their price or their terms on you. And honestly, it's a lot easier than it used to be.

## Self-hosting doesn't have to be lonely

Most self-hosting happens alone. Someone puts a few apps on a box in the garage, gets them talking to each other, puts them online, and it works. Nobody else ever sees how they did it, so the next person starts from scratch.

We'd like that to change. A setup in a garage can already serve more than its owner. Edgible gives each app its own hostname, and you choose who gets in: anyone, people in your organization, or callers with an API key. That's how you end up running the site for your club or the tools for your team.

Cards are the other half. When you've got something working that you're happy with, you write it down as a card, and someone else can run the same thing on their own machine. Maybe they tweak it and share their version back. That's the part we're most excited about.

## What's in a card

Exposing one port to the internet isn't the hard bit. The hard bit is the whole setup: which apps go together and how they find each other, which hostname is open and which needs a sign-in, what runs on which machine, how you check it works, and how you take it all down again without losing anything. That's what a card records.

Take the website card. It's the site, an editor for its pages, analytics, and an uptime monitor that you can put on a second machine, each with the right level of access.

A card never contains anything personal. No device names, hostnames, organization ids, or passwords. You fill those in yourself, on your own machine.

## Why "cards" and not a catalog

We thought about building a catalog of apps for a long time. The trouble is that a catalog is a promise: every app in it works, stays up to date, and is supported. Keeping that promise for every app out there would be a full-time job, and a fragile one.

So we made a smaller promise instead. A card belongs to whoever wrote it. It's their record of what worked for them, and they decide how it's built, down to whether they pin image versions. The apps themselves belong to their own projects, so a card gets each one running and reachable and then points you at that app's own docs. Our job at Edgible is the format and the tools around it.

## Same shape every time

Once you've used one card, you know how to use them all. Every README has the same sections (Why, What, How, Verify, Tear down) and the same steps, and the settings follow the same names. The [conventions table](README.md#publish-a-card) has the details if you're writing one.

We also wanted cards to be checkable rather than "trust me". Before you start, `check-env.py` looks at your machine for anything the card would trip over, like a port that's already taken or an app with the same name, and prints the fixes as lines you can paste. After you publish, the Verify section checks that each hostname answers the way it should. And Tear down takes everything apart in the right order, backing up your data before it deletes anything.

Because the steps are the same every time, they're easy to follow. That goes for you, and for an AI assistant if you're working with one.

## Get involved

Have a look at the [cards](README.md) and try one. If you change one to suit yourself, share it back as a variant with a name that says what's different, like `n8n-sqlite`. And if you've built something in your own garage that you're proud of, we'd love to see it as a card. [Publish a card](README.md#publish-a-card) explains how.
