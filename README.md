# Midi2Lua
Parses a MIDI string into note, time and velocity.

# Methods
* `fromString(data: string)` Create object from a string
* `fromHttp(url: string)` Create object from a URL

# Object methods
* `getHeader()` Returns the header and sets self.header
* `getNoteData(header: table?)` Returns note data (header argument optional if you called getHeader
