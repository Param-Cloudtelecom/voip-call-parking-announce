--[[
park_announce.lua

Listens for FreeSWITCH's valet_park events and triggers a spoken
announcement over the overhead paging multicast group (see
../../multicast-paging-system) naming the slot a call just parked on -
"Call parked, extension seven-oh-one" instead of relying on someone to
notice a blinking BLF lamp.

Registered as an event consumer, not tied to a single call's dialplan
execution - runs continuously, reacting to parking events system-wide.

Load via autoload_configs/lua.conf.xml startup script, or run standalone:
    fs_cli -x "lua park_announce.lua"
]]

local event_consumer = freeswitch.EventConsumer("CUSTOM", "valet_park::info")

freeswitch.consoleLog("info", "[park_announce] listening for valet_park events\n")

while true do
    local event = event_consumer:pop(1, 1000)
    if event then
        local action = event:getHeader("Valet-Action")
        local lot = event:getHeader("Valet-Lot-Name")
        local slot = event:getHeader("Valet-Extension")

        if action == "valet-parking" then
            freeswitch.consoleLog("info",
                string.format("[park_announce] call parked: lot=%s slot=%s\n", lot, slot))

            -- Speak the slot number, then bridge that TTS/recording out to
            -- the overhead paging multicast address rather than a single
            -- extension - see multicast-paging-system/README.md for the
            -- "page_announcement" application this assumes is configured.
            local announce_session = freeswitch.Session("loopback/page_announcement/default")
            if announce_session:ready() then
                announce_session:execute("set", "tts_engine=flite")
                announce_session:execute("set", "tts_voice=kal")
                announce_session:execute("speak",
                    string.format("Call parked, extension %s", slot))
                announce_session:hangup()
            end
        end
    end
end
