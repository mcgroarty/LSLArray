// Array.lsl - String Array Implementation for LSL
// Implements multiple string arrays using LSL lists
//
// Copyright (c) 2025, Brian McGroarty
// This code is licensed under the BSD 3-Clause License - see the LICENSE file for details
// This code was created with the assistance of AI
// It doesn't make me add that, but this still feels like cheating if I don't.
//
// IMPORTANT: Any changes to this implementation must be reflected in design.md
// to ensure documentation remains in sync with the code.

// Global variables to store our array system
list g_arrayInfo = []; // Stores pairs of [arrayId, arraySize]
list g_arrayData = []; // Stores all array data sequentially
integer g_enableErrorMessages = TRUE; // Set to FALSE to disable error messages

// Function to log errors if enabled
logError(string message)
{
    if (g_enableErrorMessages)
    {
        llOwnerSay("Error: " + message);
    }
}

// Validates an array ID
// Returns TRUE if valid, FALSE otherwise
// Note: Empty string is allowed as a valid array ID
integer isValidArrayId(string arrayId)
{
    // All array IDs, including empty strings, are considered valid
    return TRUE;
}

// Function to find an array's index in the info list
// Returns -1 if the array doesn't exist
integer findArrayIndex(string arrayId)
{
    // Quick validation
    if (!isValidArrayId(arrayId))
    {
        return -1;
    }
    
    integer i;
    integer len = llGetListLength(g_arrayInfo);
    
    for (i = 0; i < len; i += 2)
    {
        if (llList2String(g_arrayInfo, i) == arrayId)
        {
            return i;
        }
    }
    return -1;
}

// Function to calculate the starting offset of an array in the data list
integer getArrayOffset(string arrayId)
{
    integer infoIndex = findArrayIndex(arrayId);
    if (infoIndex == -1)
    {
        return -1; // Array not found
    }
    
    integer offset = 0;
    integer i;
    
    // Sum the sizes of all preceding arrays
    for (i = 0; i < infoIndex; i += 2)
    {
        offset += llList2Integer(g_arrayInfo, i + 1);
    }
    
    return offset;
}

// Function to set the size of an array
// If size is 0, the array is removed
// If the array doesn't exist, it's created
// If the array exists, it's resized (preserving data)
// Returns TRUE if successful, FALSE otherwise
integer setArraySize(string arrayId, integer size)
{
    // Validate input
    if (!isValidArrayId(arrayId))
    {
        return FALSE;
    }
    
    if (size < 0)
    {
        logError("Cannot set negative array size for '" + arrayId + "'");
        return FALSE;
    }
    
    integer infoIndex = findArrayIndex(arrayId);
    
    // Case 1: Array doesn't exist and we want to create it
    if (infoIndex == -1 && size > 0)
    {
        integer dataOffset = llGetListLength(g_arrayData);
        
        // Add array info
        g_arrayInfo += [arrayId, size];
        
        // Initialize with empty strings
        integer i;
        for (i = 0; i < size; ++i)
        {
            g_arrayData += [""];
        }
        return TRUE;
    }
    
    // Case 2: Array exists and we want to remove it
    if (infoIndex != -1 && size == 0)
    {
        integer oldSize = llList2Integer(g_arrayInfo, infoIndex + 1);
        integer dataOffset = getArrayOffset(arrayId);
        
        // Validate indices for delete operation
        if (dataOffset < 0 || dataOffset + oldSize > llGetListLength(g_arrayData))
        {
            logError("Invalid data indices detected for array '" + arrayId + "'. Skipping deletion to prevent corruption.");
            return FALSE;
        }
        
        // Remove array info
        g_arrayInfo = llDeleteSubList(g_arrayInfo, infoIndex, infoIndex + 1);
        
        // Remove array data
        // Only attempt to remove data if the array actually had data
        // If oldSize is 0, dataOffset + oldSize - 1 < dataOffset, causing llDeleteSubList
        // to behave as an exclusion range (deleting everything BUT the range)
        if (oldSize > 0)
        {
            g_arrayData = llDeleteSubList(g_arrayData, dataOffset, dataOffset + oldSize - 1);
        }
        return TRUE;
    }
    
    // Case 3: Array exists and we want to resize it
    if (infoIndex != -1 && size > 0)
    {
        integer oldSize = llList2Integer(g_arrayInfo, infoIndex + 1);
        integer dataOffset = getArrayOffset(arrayId);
        
        // Validate indices for resize operation
        if (dataOffset < 0 || dataOffset + oldSize > llGetListLength(g_arrayData))
        {
            logError("Invalid data indices detected for array '" + arrayId + "'. Skipping resize to prevent corruption.");
            return FALSE;
        }
        
        // Update size in array info
        g_arrayInfo = llListReplaceList(g_arrayInfo, [size], infoIndex + 1, infoIndex + 1);
        
        // If expanding, add empty strings
        if (size > oldSize)
        {
            integer i;
            list newElements = [];
            for (i = 0; i < (size - oldSize); ++i)
            {
                newElements += [""];
            }
            
            g_arrayData = llListInsertList(g_arrayData, newElements, dataOffset + oldSize);
        }
        // If shrinking, remove excess elements
        else if (size < oldSize)
        {
            g_arrayData = llDeleteSubList(g_arrayData, dataOffset + size, dataOffset + oldSize - 1);
        }
        return TRUE;
    }
    
    return FALSE; // Should never get here
}

// Function to get the size of an array
// Returns 0 if the array doesn't exist
integer getArraySize(string arrayId)
{
    // Quick validation
    if (!isValidArrayId(arrayId))
    {
        return 0;
    }
    
    integer infoIndex = findArrayIndex(arrayId);
    if (infoIndex == -1)
    {
        return 0; // Array doesn't exist
    }
    
    return llList2Integer(g_arrayInfo, infoIndex + 1);
}

// Function to write a value to an array element
// Returns TRUE if successful, FALSE if out of bounds
integer writeArrayElement(string arrayId, integer index, string value)
{
    // Quick validation
    if (!isValidArrayId(arrayId))
    {
        return FALSE;
    }
    
    // Get array information
    integer infoIndex = findArrayIndex(arrayId);
    if (infoIndex == -1)
    {
        logError("Array '" + arrayId + "' doesn't exist");
        return FALSE;
    }
    
    integer arraySize = llList2Integer(g_arrayInfo, infoIndex + 1);
    if (index < 0 || index >= arraySize)
    {
        logError("Index " + (string)index + " out of bounds for array '" + arrayId + "'");
        return FALSE;
    }
    
    // Calculate the position in the data list
    integer dataOffset = getArrayOffset(arrayId);
    integer dataIndex = dataOffset + index;
    
    // Validate the dataIndex is within bounds of the data list
    if (dataIndex >= llGetListLength(g_arrayData))
    {
        logError("Internal error: Data index out of bounds. Data may be corrupted.");
        return FALSE;
    }
    
    // Update the value
    g_arrayData = llListReplaceList(g_arrayData, [value], dataIndex, dataIndex);
    return TRUE;
}

// Function to read a value from an array element
// Returns the element's value, or empty string if the array or index doesn't exist
string readArrayElement(string arrayId, integer index)
{
    // Quick validation
    if (!isValidArrayId(arrayId))
    {
        return "";
    }
    
    // Get array information
    integer infoIndex = findArrayIndex(arrayId);
    if (infoIndex == -1)
    {
        logError("Array '" + arrayId + "' doesn't exist");
        return "";
    }
    
    integer arraySize = llList2Integer(g_arrayInfo, infoIndex + 1);
    if (index < 0 || index >= arraySize)
    {
        logError("Index " + (string)index + " out of bounds for array '" + arrayId + "'");
        return "";
    }
    
    // Calculate the position in the data list
    integer dataOffset = getArrayOffset(arrayId);
    integer dataIndex = dataOffset + index;
    
    // Validate the dataIndex is within bounds of the data list
    if (dataIndex >= llGetListLength(g_arrayData))
    {
        logError("Internal error: Data index out of bounds. Data may be corrupted.");
        return "";
    }
    
    // Return the value
    return llList2String(g_arrayData, dataIndex);
}

// Returns a list of all array IDs
list getAllArrayIds()
{
    list ids = [];
    integer i;
    integer len = llGetListLength(g_arrayInfo);
    
    for (i = 0; i < len; i += 2)
    {
        ids += [llList2String(g_arrayInfo, i)];
    }
    
    return ids;
}

// Push a value to the beginning of an array (prepend)
// Creates the array if it doesn't exist
// Returns TRUE if successful, FALSE otherwise
integer pushArrayElement(string arrayId, string value)
{
    // Validate array ID
    if (!isValidArrayId(arrayId))
    {
        return FALSE;
    }
    
    integer infoIndex = findArrayIndex(arrayId);
    integer dataOffset = -1;
    integer arraySize = 0;
    
    // If array doesn't exist, create it
    if (infoIndex == -1)
    {
        g_arrayInfo += [arrayId, 1];
        g_arrayData += [value];
        return TRUE;
    }
    
    // Array exists - get its current size and offset
    arraySize = llList2Integer(g_arrayInfo, infoIndex + 1);
    dataOffset = getArrayOffset(arrayId);
    
    // Validate dataOffset
    if (dataOffset < 0 || dataOffset > llGetListLength(g_arrayData))
    {
        logError("Invalid data indices detected for array '" + arrayId + "'. Skipping push operation.");
        return FALSE;
    }
    
    // Increase size in array info
    g_arrayInfo = llListReplaceList(g_arrayInfo, [arraySize + 1], infoIndex + 1, infoIndex + 1);
    
    // Insert new element at the front of the array
    g_arrayData = llListInsertList(g_arrayData, [value], dataOffset);
    
    return TRUE;
}

// Pop (retrieve and remove) a value from the beginning of an array
// Returns the element's value, or empty string if the array doesn't exist or is empty
// If the array becomes empty after pop, it remains as a zero-length array
string popArrayElement(string arrayId)
{
    // Validate array ID
    if (!isValidArrayId(arrayId))
    {
        return "";
    }
    
    // Check if array exists and has elements
    integer infoIndex = findArrayIndex(arrayId);
    if (infoIndex == -1)
    {
        logError("Array '" + arrayId + "' doesn't exist");
        return "";
    }
    
    integer arraySize = llList2Integer(g_arrayInfo, infoIndex + 1);
    if (arraySize <= 0)
    {
        logError("Array '" + arrayId + "' is empty");
        return "";
    }
    
    // Get data offset
    integer dataOffset = getArrayOffset(arrayId);
    if (dataOffset < 0 || dataOffset >= llGetListLength(g_arrayData))
    {
        logError("Invalid data indices detected for array '" + arrayId + "'. Skipping pop operation.");
        return "";
    }
    
    // Get the value from the front of the array
    string value = llList2String(g_arrayData, dataOffset);
    
    // Update size in array info
    g_arrayInfo = llListReplaceList(g_arrayInfo, [arraySize - 1], infoIndex + 1, infoIndex + 1);
    
    // Remove the element from the data array
    g_arrayData = llDeleteSubList(g_arrayData, dataOffset, dataOffset);
    
    return value;
}

// Append a value to the end of an array
// Creates the array if it doesn't exist
// Returns TRUE if successful, FALSE otherwise
integer appendArrayElement(string arrayId, string value)
{
    // Validate array ID
    if (!isValidArrayId(arrayId))
    {
        return FALSE;
    }
    
    integer infoIndex = findArrayIndex(arrayId);
    
    // If array doesn't exist, create it
    if (infoIndex == -1)
    {
        g_arrayInfo += [arrayId, 1];
        g_arrayData += [value];
        return TRUE;
    }
    
    // Array exists - get its current size and offset
    integer arraySize = llList2Integer(g_arrayInfo, infoIndex + 1);
    integer dataOffset = getArrayOffset(arrayId);
    
    // Validate dataOffset
    if (dataOffset < 0 || dataOffset + arraySize > llGetListLength(g_arrayData))
    {
        logError("Invalid data indices detected for array '" + arrayId + "'. Skipping append operation.");
        return FALSE;
    }
    
    // Increase size in array info
    g_arrayInfo = llListReplaceList(g_arrayInfo, [arraySize + 1], infoIndex + 1, infoIndex + 1);
    
    // Add new element at the end of the array
    g_arrayData = llListInsertList(g_arrayData, [value], dataOffset + arraySize);
    
    return TRUE;
}

// Enable or disable error messages
setErrorMessagesEnabled(integer enabled)
{
    g_enableErrorMessages = enabled;
}

// Example usage in default state
default
{
    state_entry()
    {
        llOwnerSay("\n\n\n\n\n\n\n\n\nString Array System Initialized");
        
        // Example: Create and manipulate arrays
        setArraySize("names", 3);
        setArraySize("colors", 2);
        setArraySize("", 1); // Create an array with empty string as identifier
        
        writeArrayElement("names", 0, "Alice");
        writeArrayElement("names", 1, "Bob");
        writeArrayElement("names", 2, "Charlie");
        
        writeArrayElement("colors", 0, "Red");
        writeArrayElement("colors", 1, "Blue");
        
        writeArrayElement("", 0, "Default"); // Write to the unnamed array
        
        llOwnerSay("names[1] = " + readArrayElement("names", 1));
        llOwnerSay("colors[0] = " + readArrayElement("colors", 0));
        llOwnerSay("unnamed[0] = " + readArrayElement("", 0));
        
        llOwnerSay("Resizing names array...");
        setArraySize("names", 4);
        writeArrayElement("names", 3, "David");
        
        llOwnerSay("names array size: " + (string)getArraySize("names"));
        
        integer i;
        for (i = 0; i < getArraySize("names"); ++i)
        {
            llOwnerSay("names[" + (string)i + "] = " + readArrayElement("names", i));
        }
        
        // Testing queue/stack operations
        llOwnerSay("\nTesting Queue/Stack Operations:");
        
        // Test push (prepend)
        llOwnerSay("\n1. Testing pushArrayElement:");
        pushArrayElement("queue", "First");
        pushArrayElement("queue", "Second");
        pushArrayElement("queue", "Third");
        
        llOwnerSay("Queue contents after pushing three items:");
        for (i = 0; i < getArraySize("queue"); ++i)
        {
            llOwnerSay("queue[" + (string)i + "] = " + readArrayElement("queue", i));
        }
        
        // Test pop (remove from front)
        llOwnerSay("\n2. Testing popArrayElement:");
        string popped = popArrayElement("queue");
        llOwnerSay("Popped value: " + popped);
        
        llOwnerSay("Queue contents after popping:");
        for (i = 0; i < getArraySize("queue"); ++i)
        {
            llOwnerSay("queue[" + (string)i + "] = " + readArrayElement("queue", i));
        }
        
        // Test append (add to end)
        llOwnerSay("\n3. Testing appendArrayElement:");
        appendArrayElement("queue", "Fourth");
        appendArrayElement("queue", "Fifth");
        
        llOwnerSay("Queue contents after appending:");
        for (i = 0; i < getArraySize("queue"); ++i)
        {
            llOwnerSay("queue[" + (string)i + "] = " + readArrayElement("queue", i));
        }
        
        // Test pop until empty
        llOwnerSay("\n4. Testing pop until empty:");
        while (getArraySize("queue") > 0)
        {
            llOwnerSay("Popped: " + popArrayElement("queue"));
        }
        
        llOwnerSay("Queue size after popping all: " + (string)getArraySize("queue"));
        
        // Test stack operations (LIFO)
        llOwnerSay("\n5. Testing stack operations (Last In First Out):");
        pushArrayElement("stack", "Bottom");
        pushArrayElement("stack", "Middle");
        pushArrayElement("stack", "Top");
        
        llOwnerSay("Stack contents:");
        for (i = 0; i < getArraySize("stack"); ++i)
        {
            llOwnerSay("stack[" + (string)i + "] = " + readArrayElement("stack", i));
        }
        
        llOwnerSay("Popping from stack: " + popArrayElement("stack"));
        llOwnerSay("Popping from stack: " + popArrayElement("stack"));
        llOwnerSay("Popping from stack: " + popArrayElement("stack"));
    }
    
    touch_start(integer total_number)
    {
        llOwnerSay("Touch received - demonstrating array operations");
        
        // Create a new array
        setArraySize("test", 3);
        writeArrayElement("test", 0, "Item 1");
        writeArrayElement("test", 1, "Item 2");
        writeArrayElement("test", 2, "Item 3");
        
        // Display array contents
        integer i;
        for (i = 0; i < getArraySize("test"); ++i)
        {
            llOwnerSay("test[" + (string)i + "] = " + readArrayElement("test", i));
        }
        
        // Remove an array
        llOwnerSay("Removing colors array...");
        setArraySize("colors", 0);
        
        // Show remaining arrays
        llOwnerSay("Remaining arrays:");
        i = 0;
        while (i < llGetListLength(g_arrayInfo))
        {
            string id = llList2String(g_arrayInfo, i);
            integer size = llList2Integer(g_arrayInfo, i + 1);
            llOwnerSay("Array '" + id + "' - size: " + (string)size);
            i += 2;
        }
    }
}