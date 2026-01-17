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

// VERIFICATION TEST CASE
// Upload this script to Second Life to verify the fix
default
{
    state_entry()
    {
        llOwnerSay("Verification Test Starting...");

        // 1. Create a "victim" array with some data
        setArraySize("victim", 2);
        writeArrayElement("victim", 0, "SAVE_ME");
        writeArrayElement("victim", 1, "PLEASE");
        llOwnerSay("Created victim array. Data[0]: " + readArrayElement("victim", 0));

        // 2. Create a "killer" array
        setArraySize("killer", 1);

        // 3. Make "killer" empty (size 0) but still existing
        // We use popArrayElement because setArraySize(..., 0) would remove it immediately
        popArrayElement("killer");
        llOwnerSay("Created empty killer array. Size: " + (string)getArraySize("killer"));

        // 4. Remove "killer" using setArraySize(..., 0)
        // This is where the bug happened
        llOwnerSay("Removing empty killer array...");
        setArraySize("killer", 0);

        // 5. Check if "victim" data survived
        string s = readArrayElement("victim", 0);
        if (s == "SAVE_ME")
        {
            llOwnerSay("TEST PASSED: Victim data survived.");
        }
        else
        {
            llOwnerSay("TEST FAILED: Victim data lost! Value is: '" + s + "'");
        }
    }
}
