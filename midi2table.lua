function readMIDIHeader(data)
    local header = {}
    -- Read the first 4 bytes and check if it's "MThd"
    local chunkType = string.sub(data, 1, 4)
    if chunkType ~= "MThd" then
        return warn("Not a valid MIDI file")
    end
    -- Read the next 4 bytes, which is the length of the header
    local chunkLength = string.unpack(">I4", string.sub(data, 5, 8))
    -- Read the next 2 bytes for the MIDI format
    header.format = string.unpack(">I2", string.sub(data, 9, 10))
    -- Read the next 2 bytes for the number of tracks
    header.numTracks = string.unpack(">I2", string.sub(data, 11, 12))
    -- Read the next 2 bytes for the time division
    header.timeDivision = string.unpack(">I2", string.sub(data, 13, 14))
    return header
end

function readMIDIData(data, header)
    assert(header == nil, "No header specified")
    local tracks = {}
    local offset = 14 -- offset starts after the header
    for i = 1, header.numTracks do
        local track = {}
        -- Read the track chunk type
        local chunkType = string.sub(data, offset + 1, offset + 4)
        assert(chunkTyle == "MTrk", "Invalid chunk track type")
        -- Read the track chunk length
        local chunkLength = string.unpack(">I4", string.sub(data, offset + 5, offset + 8))
        -- set the offset to the start of the track data
        offset = offset + 9
        local trackData = string.sub(data, offset, offset + chunkLength - 1)
        offset = offset + chunkLength
        local noteTable = {}
        local time = 0
        local runningStatus = nil
        -- Iterate through the track data
        while offset < #data do
            -- read delta time
            local deltaTime, index = string.unpack(">I4", trackData, offset)
            offset = offset + index
            time = time + deltaTime

            -- read event
            local event = string.byte(trackData, offset)
            offset = offset + 1

            if event == 0xF0 or event == 0xF7 then
                -- SysEx event, read the length and ignore the data
                local length, index = string.unpack(">I4", trackData, offset)
                offset = offset + index + length
            elseif event == 0xFF then
                -- Meta event, read the type and length
                local type = string.byte(trackData, offset)
                offset = offset + 1
                local length, index = string.unpack(">I4", trackData, offset)
                offset = offset + index
                if type == 0x2F then
                    -- End of track event, stop reading
                    break
                else
                    -- Ignore other meta events
                    offset = offset + length
                end
            else
                -- MIDI event
                if event < 0x80 then
                    -- Running status, use the last status byte
                    event = runningStatus
                    offset = offset - 1
                else
                    runningStatus = event
                end

                if event >= 0x90 and event < 0xA0 then
                    -- Note on event
                    local noteNumber = string.byte(trackData, offset)
                    offset = offset + 1
                    local velocity = string.byte(trackData, offset)
                    offset = offset + 1
                    -- add to noteTable
                    noteTable[#noteTable + 1] = {time = time, noteNumber = noteNumber, velocity = velocity}
                elseif event >= 0x80 and event < 0x90 then
                    -- Note off event
                    local noteNumber = string.byte(trackData, offset)
                    offset = offset + 1
                    local velocity = string.byte(trackData, offset)
                    offset = offset + 1
                    -- subtract from noteTable
                    noteTable[#noteTable + 1] = {time = time, noteNumber = noteNumber, velocity = velocity}
                else
                    -- Ignore other events
                    local param1 = string.byte(trackData, offset)
                    offset = offset + 1
                    local param2 = nil
                    if event >= 0xC0 and event < 0xE0 then
                        -- 1 parameter event
                    elseif event >= 0xA0 and event < 0xC0 then
                        -- 2 parameter event
                        param2 = string.byte(trackData, offset)
                        offset = offset + 1
                    end
                end
            end
        end
        tracks[i] = {noteTable = noteTable}
    end
    return tracks
end

local midiReader = {}
midiReader.__index = midiReader

function midiReader.fromString(mstr)
   return setmetatable({
       file = mstr
   }, midiReader)
end

function midiReader.fromHttp(url)
   local mstr = game:GetService("HttpService"):GetAsync(url)
   return setmetatable({
       file = mstr
   }, midiReader)
end

function midiReader:getHeader()
   self.header = readMIDIHeader(self.file)
   return self.header
end

function midiReader:getNoteData(header)
   return readMIDIData(self.file, header or self.header)
end

return midiReader