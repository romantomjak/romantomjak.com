---
title: "Hetzner DIY Private Networking with tinc"
date: 2018-08-18T20:14:39+01:00
draft: true
tags: ["hetzner", "tinc"]
categories: ["cloud"]
summary: Hetzner is lacking Private Networking feature. Tinc is a VPN daemon that offers full mesh routing. Roman is a guy that has recompiled Kernel over a dozen times because he forgot to enable a feature. Ingredients for great success!
---

[Hetzner](https://www.hetzner.com/) has a reputation for offering a sweet price/performance ratio however, in a true Unix philosophy, it comes at a cost of needing to do everything by yourself. Luckily, I am a guy who has recompiled his kernel over a dozen of times because I've forgotten to enable a feature. Here I'm obviously refering to my hard-working persona and not my 640K memory, which btw, should be enough for everyone, haha!

## tinc and why do I even

Usually, VPN uses a client-server architecture that gives you a star shaped topology where everything has to go through the central node, but that's not quite what I want. I need a peer-to-peer network where every node is connected to all the other nodes.

{{< figure width="680" src="/media/network-topology.png" alt="Network Topology" >}}

[tinc](http://tinc-vpn.org/) is a Virtual Private Network daemon that uses tunnelling and encryption to provide full mesh routing or in other words, whenever possible, traffic is always sent directly to the destination, without going through intermediate hops. Additionally, because the VPN appears as a normal network device, there is no need to adapt any existing software!

## yes yes, but will this count against my outgoing traffic?

Not according to [Hetzner](https://wiki.hetzner.de/index.php/CloudServer/en):

> We only bill for outgoing traffic. Incoming and internal traffic is free. **Internal traffic includes other Hetzner Cloud servers**, other Hetzner Online dedicated root servers, and other Hetzner Online servers, services, or web hosting packages.

## cool, show me the config

Here's my [ansible playbook](https://github.com/romantomjak/ansible-roles/playbooks/tinc.yml) and a friendly reminder to read the [documentation](http://tinc-vpn.org/documentation), but ain't nobody got time for that, so here's my config instead:

```sh
ConnectTo = host1, host2
```
