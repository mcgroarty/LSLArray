# Array.lsl
An implementation of arrays in Linden Scripting Language, the Second Life scripting language

## Overview
This library provides a way to create and manage multiple string arrays in LSL, which doesn't natively support arrays. See the `design.md` file for detailed documentation on how to use this library.

## Features
- Create multiple named string arrays in a single script
- Dynamic resizing of arrays (expand or shrink)
- Basic array operations: get/set elements, get size
- Queue and stack operations: push, pop, append
- Support for empty string array identifiers
- Error checking and validation

## Usage
```lsl
// Basic array operations
setArraySize("myArray", 5);               // Create array
writeArrayElement("myArray", 0, "Hello"); // Write to array
string value = readArrayElement("myArray", 0); // Read from array

// Queue operations
pushArrayElement("queue", "First");      // Add to front
appendArrayElement("queue", "Last");     // Add to end
string item = popArrayElement("queue");  // Remove from front
```

## License
This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025, Brian McGroarty

This code was created with the assistance of AI (GitHub Copilot)
It doesn't make me add that, but this still feels like cheating if I don't.