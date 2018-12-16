---
title: "Parsing and returning JSON in Go"
date: 2018-12-15T11:21:06Z
draft: false
tags: ["rest"]
categories: ["go"]
summary: Sending and receiving JSON is a pretty common thing to do, but coming from a duck typed language it may seem like a rather difficult thing to do and Go documentation, albeit complete, is not always the easiest thing to understand.
---

Imagine you're working for the worlds largest Wool Sock provider _WOOSOK_, handling on average 90k requests a day through your eCommerce platform of choice. It's 11 AM on a Monday morning, you're browsing Hacker News, when suddenly your boss Slacks you asking why "the website is slow". You open the home page of WOOSOK and indeed, it took 8s to load the home page.

Twenty minutes later you've narrowed it down to a particular URL that when visited generates a list of all Purchase Orders ever created. Quick look at the HTTP response times in Grafana reveals that this has been happening for a while now, exactly at 11 AM.

Turns out, your New Zealand yarn provider has implemented automated PO approvals with a nifty Selenium script that runs at midnight. The script visits the aforementioned URL, opens the detail view of an unapproved PO, approves it and then goes back and loads the dangerous URL again. This goes on until it has approved all POs for the day, which on average is around 100.

[ XKCD IMAGE BEGIN ]

"13 minutes of outage during our peak sales hours is outrageous", yells your boss. "You have to do something!". You comfort him and tell him you already have a plan - you're going to extract all PO related functionality into a microservice. It will not affect the website and will allow the provider to continue to use his script.

[ EOF XKCD IMAGE ]

## Marshaling JSON data

This functionality is provided by the standard library package `encoding/json`. Go is statically typed, meaning, that compiler needs to know what data types are you going to use at compile time.

- talk about structs
- how to exclude fields

## Unmarshaling JSON data

- parsing into interface{}
