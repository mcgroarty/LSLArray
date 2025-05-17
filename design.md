# LSL Array Library Design Document

## Overview

The LSL Array library implements an arbitrary number of arrays that store strings. Since LSL does not natively support arrays, this implementation uses a custom data structure with two lists:

1. An array information list (`g_arrayInfo`) that stores pairs of array identifiers and their sizes
2. A data list (`g_arrayData`) that contains all the actual string values sequentially

## Implementation Details

### Data Structure
- `g_arrayInfo`: A list containing pairs of array identifiers (strings) and array sizes (integers)
- `g_arrayData`: A list containing all array elements sequentially

### Key Functions

1. **setArraySize(string arrayId, integer size)**
   - Creates a new array if it doesn't exist
   - Removes an array if size is set to 0
   - Resizes an existing array while preserving data (trimming or extending as needed)

2. **getArraySize(string arrayId)**
   - Returns the size of an array
   - Returns 0 if the array doesn't exist

3. **writeArrayElement(string arrayId, integer index, string value)**
   - Writes a string value to a specific array element
   - Returns TRUE if successful, FALSE if array doesn't exist or index is out of bounds

4. **readArrayElement(string arrayId, integer index)**
   - Reads a string value from a specific array element
   - Returns empty string if array doesn't exist or index is out of bounds

5. **pushArrayElement(string arrayId, string value)**
   - Inserts a value at the beginning of an array (prepend)
   - Creates the array if it doesn't exist
   - Returns TRUE if successful, FALSE otherwise

6. **popArrayElement(string arrayId)**
   - Retrieves and removes a value from the beginning of an array
   - Returns the element's value, or empty string if the array doesn't exist or is empty
   - If the array becomes empty after pop, it remains as a zero-length array

7. **appendArrayElement(string arrayId, string value)**
   - Adds a value to the end of an array
   - Creates the array if it doesn't exist
   - Returns TRUE if successful, FALSE otherwise

### Helper Functions

1. **findArrayIndex(string arrayId)**
   - Finds the position of an array in the info list
   - Returns -1 if the array doesn't exist

2. **getArrayOffset(string arrayId)**
   - Calculates the starting position of an array in the data list
   - Sums up the sizes of all preceding arrays

## Usage Instructions

### Including the Library in Your Script

Copy the functions and global variables from Array.lsl into your script:
- Global variables: `g_arrayInfo` and `g_arrayData`
- Helper functions: `findArrayIndex` and `getArrayOffset`
- Core functions: `setArraySize`, `getArraySize`, `writeArrayElement`, and `readArrayElement`
- Queue/Stack functions: `pushArrayElement`, `popArrayElement`, and `appendArrayElement`

### Basic Usage

1. **Creating Arrays**
   ```lsl
   setArraySize("myArray", 5); // Create an array named "myArray" with 5 elements
   setArraySize("", 3); // Create an array with an empty string as the identifier
   ```

2. **Writing Values**
   ```lsl
   writeArrayElement("myArray", 0, "First element");
   writeArrayElement("myArray", 4, "Last element");
   writeArrayElement("", 0, "Element in unnamed array");
   ```

3. **Reading Values**
   ```lsl
   string value = readArrayElement("myArray", 2);
   string unnamed = readArrayElement("", 0); // Read from the unnamed array
   ```

4. **Resizing Arrays**
   ```lsl
   setArraySize("myArray", 10); // Expand to 10 elements (preserves existing data)
   setArraySize("myArray", 3);  // Shrink to 3 elements (truncates data)
   ```

5. **Removing Arrays**
   ```lsl
   setArraySize("myArray", 0); // Removes the array
   ```

6. **Queue Operations**
   ```lsl
   // Creating a queue
   pushArrayElement("queue", "First Item");   // Add at beginning
   appendArrayElement("queue", "Last Item");  // Add at end
   
   // Retrieving and removing items
   string item = popArrayElement("queue");    // Get and remove from beginning
   ```

7. **Stack Operations**
   ```lsl
   // Creating a stack
   pushArrayElement("stack", "Bottom Item");  // Push first item
   pushArrayElement("stack", "Top Item");     // Push second item (goes on top)
   
   // Removing items (LIFO - Last In First Out)
   string item = popArrayElement("stack");    // Gets "Top Item"
   ```

### Common Data Structure Examples

1. **Stack Implementation**
   ```lsl
   // Initialize stack
   setArraySize("stack", 0);
   
   // Push operation
   integer push(string value) {
       return pushArrayElement("stack", value);
   }
   
   // Pop operation
   string pop() {
       return popArrayElement("stack");
   }
   
   // Peek operation (view top element without removing)
   string peek() {
       if (getArraySize("stack") > 0) {
           return readArrayElement("stack", 0);
       }
       return "";
   }
   
   // Check if stack is empty
   integer isEmpty() {
       return getArraySize("stack") == 0;
   }
   ```

2. **Queue Implementation**
   ```lsl
   // Initialize queue
   setArraySize("queue", 0);
   
   // Enqueue operation (add to end)
   integer enqueue(string value) {
       return appendArrayElement("queue", value);
   }
   
   // Dequeue operation (remove from front)
   string dequeue() {
       return popArrayElement("queue");
   }
   
   // Peek operation (view front element without removing)
   string peek() {
       if (getArraySize("queue") > 0) {
           return readArrayElement("queue", 0);
       }
       return "";
   }
   
   // Check if queue is empty
   integer isEmpty() {
       return getArraySize("queue") == 0;
   }
   ```

3. **Simple Set Implementation**
   ```lsl
   // Check if an element exists in the set
   integer contains(string setId, string value) {
       integer size = getArraySize(setId);
       integer i;
       for (i = 0; i < size; ++i) {
           if (readArrayElement(setId, i) == value) {
               return TRUE;
           }
       }
       return FALSE;
   }
   
   // Add an element to the set (if it doesn't already exist)
   integer addToSet(string setId, string value) {
       if (!contains(setId, value)) {
           return appendArrayElement(setId, value);
       }
       return TRUE; // Element already exists
   }
   
   // Remove an element from the set
   integer removeFromSet(string setId, string value) {
       integer size = getArraySize(setId);
       integer i;
       for (i = 0; i < size; ++i) {
           if (readArrayElement(setId, i) == value) {
               // Remove by copying last element to this position
               // (unless this is the last element)
               if (i < size - 1) {
                   string lastElement = readArrayElement(setId, size - 1);
                   writeArrayElement(setId, i, lastElement);
               }
               // Resize array to remove last element
               setArraySize(setId, size - 1);
               return TRUE;
           }
       }
       return FALSE; // Element not found
   }
   ```

### Important Notes

1. The example code in `state_entry()` and `touch_start()` functions in the Array.lsl file is for demonstration purposes only. You should remove or replace this code when implementing the library in your own scripts.

2. All array indices are zero-based (0 to size-1).

3. Empty string (`""`) is a valid array identifier. You can create, access, and manipulate arrays with an empty string as their identifier.

4. Error checking is built into the functions, with error messages sent via `llOwnerSay()`. You may want to modify these for your specific needs.

5. Memory usage increases with the number and size of arrays. In LSL, lists have memory limitations, so be mindful of this when creating large or numerous arrays. This implementation is designed to be optimal for smaller arrays.

## Performance Considerations

1. **Memory Usage**
   - Each array requires storage in both the `g_arrayInfo` and `g_arrayData` lists
   - Total memory usage grows with the number of arrays and total elements
   - Consider using fewer, larger arrays rather than many small arrays when possible

2. **Operation Efficiency**
   - `readArrayElement` and `writeArrayElement` require calculating offsets each time
   - `pushArrayElement` is more expensive than `appendArrayElement` as it requires shifting elements
   - Frequent resizing of arrays can be expensive; try to allocate appropriate sizes upfront
   - Queue operations have O(1) complexity at each end, but O(n) for element access by index

3. **Error Handling**
   - Set `g_enableErrorMessages` to FALSE in production scripts if you manage errors yourself
   - All functions include proper validation to prevent data corruption

## Maintenance Note

**Important**: This design document must be updated whenever changes are made to the Array.lsl script to ensure documentation remains in sync with implementation. Similarly, any conceptual changes made here should be reflected in the Array.lsl implementation.