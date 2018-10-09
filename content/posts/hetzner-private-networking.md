---
title: "Hetzner DIY Private Networking with tinc"
date: 2018-10-09T22:06:52+01:00
draft: false
tags: ["hetzner", "tinc", "ansible"]
categories: ["infrastructure"]
summary: Hetzner is lacking Private Networking feature. Tinc is a VPN daemon that offers full mesh routing. Roman is a guy that has recompiled Kernel over a dozen times because he forgot to enable a feature. Ingredients for great success!
---

[Hetzner](https://www.hetzner.com/) has a reputation for offering a sweet price/performance ratio, however, in a true Unix philosophy, it comes at a cost of having to do everything by yourself. Including Private Networking. Normally you only get one public IP and no private interfaces. I suspect they might have some clever routing rules in place for traffic to never leave the DC, but somehow I don't really fancy sending unencrypted traffic over public IPs.

Luckily, I am a guy who has recompiled his kernel over a dozen of times because I've forgotten to enable a feature! Here I'm obviously referring to my hard-working persona and not my 640K memory, which btw, should be enough for everyone, haha!

## tinc vs traditional VPN solutions

Usually, Virtual Private Network (VPN) solutions have a client-server architecture that gives you a star shaped topology, where everything has to go through a central node, but that's not quite what I want. I want a peer-to-peer network where every node is connected to all the other nodes. Think LAN, only more resilient.

{{< figure width="680" src="/media/network-topology.png" class="center" alt="Network Topology" >}}

Full mesh routing via tunnelling and encryption is exactly what [tinc](http://tinc-vpn.org/) does. Additionally, whenever possible, it will always send traffic directly to the destination, without going through any intermediate hops and because the VPN appears as a normal network device, there is no need to adapt any existing software! #mindblown

## Private Networking and Outgoing Traffic costs

If you're wondering whether this DIY Private Network will count against your outgoing traffic, then according to [Hetzner](https://wiki.hetzner.de/index.php/CloudServer/en) the answer is **NO** (emphasis mine):

> We only bill for outgoing traffic. Incoming and internal traffic is free. **Internal traffic includes other Hetzner Cloud servers**, other Hetzner Online dedicated root servers, and other Hetzner Online servers, services, or web hosting packages.

## DIY Private Network vs DigitalOcean's Private Networking

I had great fun with `tcpdump`, `iptables` and `PKCS` while working on this DIY private network. And by great fun, I of course mean me not reading the docs, misconfiguring things and then staring at the screen dumbfoundedly when things don't work as expected. So, naturally, this would all be a big waste of time if I wouldn't benchmark it against something! I picked [DigitalOcean](https://blog.digitalocean.com/introducing-private-networking/) as they offer Private Networking as a simple tick box when creating a droplet. Ughhh, that cuts deep.

My objective is to run two tests - one where traffic goes over an encrypted tunnel and one without encryption. The outcome will be the average of 5 runs for each test.

Here's my test setup:

- Hetzner nodes will be in Falkenstein, Germany
- DigitalOcean nodes will be in Frankfurt, Germany
- Tested with 2 GB RAM and 1 vCPU nodes

Both DC locations are reasonably close to each other, so for me this will be as fair as it gets. Here's my [example playbook](https://github.com/romantomjak/ansible-roles/tree/master/tinc) that I used for creating the mesh networks.

### Hetzner

First test was no encryption run between two nodes. Allegedly, this still counts as _internal_ traffic, so some black art has been applied. In any case, my test runs were clocking in at about **6.5 Gbits/sec**:

```sh
$ iperf -c x.x.x.x
------------------------------------------------------------
Client connecting to x.x.x.x, TCP port 5001
TCP window size: 85.0 KByte (default)
------------------------------------------------------------
[  3] local x.x.x.x port 47526 connected with x.x.x.x port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec  7.12 GBytes  6.12 Gbits/sec
```

OMG, do you see it? 6.12 Gbits/sec!

Second test was over an encrypted tunnel between two nodes, averaging at about 390 Mbit/s:

```sh
$ iperf -c 10.10.1.x
------------------------------------------------------------
Client connecting to 10.10.1.x, TCP port 5001
TCP window size: 45.0 KByte (default)
------------------------------------------------------------
[  3] local 10.10.1.x port 43714 connected with 10.10.1.x port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec   460 MBytes   386 Mbits/sec
```

### DigitalOcean

Same process - average of 5 runs for each test. One caveat tho - here I used the provided Private Network to run my tests.

Bandwidth was averaging at about 1.4 Gbits/s for unencrypted traffic:

```sh
$ iperf -c x.x.x.x
------------------------------------------------------------
Client connecting to x.x.x.x, TCP port 5001
TCP window size: 85.0 KByte (default)
------------------------------------------------------------
[  3] local x.x.x.x port 59560 connected with x.x.x.x port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec  1.57 GBytes  1.35 Gbits/sec
```

Things weren't looking so great over an encrypted tunnel, _only_ 200 Mbit/sec compared to Hetzner's 390 Mbit/s:

```sh
$ iperf -c 10.10.1.x
------------------------------------------------------------
Client connecting to 10.10.1.x, TCP port 5001
TCP window size: 45.0 KByte (default)
------------------------------------------------------------
[  3] local 10.10.1.x port 46910 connected with 10.10.1.x port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec   237 MBytes   199 Mbits/sec
```

So, yeah. Hetzner kicks ass.
