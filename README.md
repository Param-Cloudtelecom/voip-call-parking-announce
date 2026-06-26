# voip-call-parking-announce

Call parking with an **automatic spoken announcement** over overhead
paging — park a call and the office hears "Call parked, extension 701"
immediately, instead of relying on someone noticing a blinking BLF lamp or
walking over to ask.

## Why park-and-announce, not just park

Stock call parking (FreeSWITCH `valet_park`, Asterisk `ParkAndAnnounce`)
solves "put this call somewhere retrievable." It doesn't solve "tell the
right person it's there" — that's still a manual, error-prone step in most
deployments, and it's the actual reason parked calls get forgotten and
callers sit on hold far longer than anyone intended.

## How it works

```
 Receptionist parks call (dials 7xx) ──► valet_park (lot=acme_parking_lot, slot=xx)
                                                  │
                                          fires valet_park::info event
                                                  │
                                                  ▼
                                      park_announce.lua (event consumer)
                                                  │
                                      TTS: "Call parked, extension xx"
                                                  │
                                                  ▼
                              Overhead paging multicast group
                         (see multicast-paging-system in this profile)
```

[`freeswitch/park_announce.xml`](freeswitch/park_announce.xml) — the
dialplan extension (`7xx`) that parks the call into a named lot/slot.

[`freeswitch/park_announce.lua`](freeswitch/park_announce.lua) — a
standalone event consumer (not tied to the parking call's own dialplan
execution) that listens for `valet_park::info` events system-wide and
triggers a TTS announcement naming the slot, routed out through the
overhead paging multicast address.

## Setup

```bash
cp freeswitch/park_announce.xml /etc/freeswitch/dialplan/acme_park.xml
cp freeswitch/park_announce.lua /etc/freeswitch/scripts/

# Run as a long-lived background script (see autoload_configs/lua.conf.xml
# for the startup-script pattern, or run manually for testing):
fs_cli -x "bgapi lua park_announce.lua"

fs_cli -x "reloadxml"
```

## Pairs with

- [`multicast-paging-system`](https://github.com/Param-Cloudtelecom/multicast-paging-system) —
  the overhead paging group this announcement actually plays over
- [`freeswitch-cloud-pbx`](https://github.com/Param-Cloudtelecom/freeswitch-cloud-pbx) —
  the multi-tenant dialplan structure this extension slots into
