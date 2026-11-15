<!--
  Privacy policy of the app, version for the first beta (14 Nov 2026; working name “Vaqt” since 15 Nov 2026,
  spec § 9.13). English counterpart of
  docs/DATENSCHUTZ.md; the German text is the reference.
  Address: this file on GitHub once the repo is public (decided 14 Nov 2026, „GitHub, beim Quellcode“).
  Before publishing: fill in the placeholders and have the text reviewed.
-->

# Privacy Policy for the App “Vaqt”

Last updated: 15 November 2026

**In short:** The app collects no data. There is no account, no advertising, no analytics and no server of our own. What you set up stays on your iPhone. The app only goes online for two things, and only to Apple’s map service: to get the name of your location and to show suggestions in the city search.

## Responsible

TODO(placeholder): name, postal address and email address of the app’s provider.

## What stays on your iPhone

The app stores on your device:

- your settings: calculation method, Asr, high-latitude rule, minute adjustments, notifications and reminder, sound, appearance and language,
- the selected city, your saved cities and the last location found,
- your numbers for making up missed prayers.

This data is kept in the app’s storage. Widgets and the Live Activity read it from a shared area of the app on the same device (App Group). We have no access to it. If you delete the app, it is gone. A backup of your iPhone (iCloud or computer) includes it, as it does the data of other apps.

## Location

With your permission (“While Using the App”), the app determines your location. It only requests a coarse location, accurate to about three kilometres; iOS may still provide a more precise one. From your location, the app calculates the prayer times and the Qibla direction on the device.

To show the name of your location, for example “Berlin”, the app sends the coordinates to Apple’s map service (MapKit). It gets back the name, country and time zone. The request goes directly to Apple; nothing reaches us.

Without permission, you choose your city by hand. You can change the permission at any time in the iOS Settings under Privacy & Security › Location Services. If you turn off “Precise Location” there, the app only gets an approximate location, which is enough for prayer times.

## City search

When you search for a city, the text you type goes to Apple’s map service so that suggestions appear. When you pick one, its coordinates come back. This, too, goes directly to Apple.

Requests to the map service are covered by [Apple’s Privacy Policy](https://www.apple.com/legal/privacy/).

## Notifications, widgets and Live Activity

The app schedules the prayer time notifications on the iPhone itself; there is no server sending them. Widgets and the Live Activity also calculate on the device, from the app’s current state. About once a day, iOS briefly wakes the app in the background so it can schedule the next notifications. Nothing leaves the device then either.

## Sharing and links

- When you share a verse, you choose in the iOS share sheet where it goes. When you copy it, it is on the clipboard.
- “Source Code” in the settings opens the project’s page on GitHub in your browser. GitHub’s privacy policy applies there.

## What Apple collects

You get the app from the App Store or, as a beta, through TestFlight. Apple processes data under its own terms, for example about your Apple Account and your downloads. If you have allowed sharing analytics with app developers in the iOS Settings, Apple passes crash reports and usage statistics on to us, which according to Apple do not identify you personally.

## Beta through TestFlight

If you test a beta through TestFlight, Apple passes the following on to us:

- your name and email address if we invited you by email; not if you joined through a public link,
- device model, iOS version and device language, installations and the number of sessions,
- crash reports that TestFlight collects automatically,
- feedback you send through TestFlight, with screenshots, comments and the device details TestFlight collects with it.

We use this information only to improve the app and do not pass it on. The legal basis is our legitimate interest in testing the app before its release (Art. 6(1)(f) GDPR). TODO(placeholder): how long we keep the information, for example until the end of the beta. What Apple collects with TestFlight and how long Apple keeps it is described in [TestFlight & Privacy](https://www.apple.com/legal/privacy/data/en/test-flight/).

## Your rights

Under the General Data Protection Regulation, you have the right of access, rectification, erasure, restriction of processing, data portability and objection. Because the app sends no data to us, we hold nothing about you outside TestFlight. For the information from TestFlight, contact the address above. You also have the right to lodge a complaint with a data protection supervisory authority.

## Changes

If something changes in the app that affects your privacy, we will update this policy. The date above shows when it was last updated.
