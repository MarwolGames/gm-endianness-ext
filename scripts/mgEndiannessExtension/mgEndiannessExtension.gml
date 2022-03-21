/**************************************************************************************************

  Copyright 2022 Marwol Games

  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
  except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  either express or implied. See the License for the specific language governing permissions and
  limitations under the License.

***************************************************************************************************

  This script includes extensions to the GameMaker's built-in functions to allow for dealing with
  endianness when processing data. Custom code is therefore injected between the user code and
  the native, built-in, GameMaker code in order to add this functionality. This means that just
  adding this script to a project is enough to start leveraging its extensions, as all relevant
  built-in functions will seemlessly be replaced by the extended variants.

  The code in this script is structured into the following #regions for easy navigation and
  customizability:

    - Configuration: a set of macros that drive the behaviour of these code extensions. These
      macros are meant to be overridden by the user on a configuration-specific basis in
      order to configure the behaviour based on different targets, build types, etc. Due to
      this, the default values attempt to provide the most developer-centric experience.

    - Code Injection: the mechanism responsible for providing the code injection capabilities
      of these code extensions. The section comment explains in detail how the mechanism
      works so that the user can correct any potential issues without being dependent on a
      new version of the extension being released.

    - Extension Code: all of the code pertaining to the implementation of these code
      extensions that does not fall into one of the other regions.

    - Validation: a collection of self-contained, automated tests that assure the user of the
      correctness of their configuration.

  For any improvements, suggestions or bug reports please reach out to us.

***************************************************************************************************

  Version: 0.1.0
  Last Modified: 21 March 2022

    v0.1.0:
      - Initial implementation of the endianness extensions.

**************************************************************************************************/

#region Configuration

///
/// Configuration option that dictates whether the built-in functions should be seemlessly replaced
/// by the extended versions or not.
///
/// This configuration option largely affects how these extensions are used. Firstly, it should
/// always be set to a boolean expression that can be evaluated at compile time (e.g. using true or
/// false directly). Secondly, if this configuration option evaluates to true then using the
/// built-in functions or the extended functions directly will yield the same result (as one is
/// replaced by the other). However, if this configuration option evaluates to false then the
/// extended functions must be used directly as the built-in functions are not replaced.
///
/// The intended way these extensions are meant to be used is by replacing the built-in functions
/// with the extended versions (meaning this configuration option should evaluate to true).
/// However, there might be scenarios in which it isn't performant to replace every invocation of
/// the built-in functions by the extended versions. In those cases this configuration option
/// should be set to false and the extended functions should be used directly in the places in
/// which they are needed.
///
/// This distinction is left to the user as we cannot know which case applies, but we default to
/// enabling the replacement of the built-in functions as it provides the best integration of the
/// endianness extensions.
///
/// @constant {Bool} ENDIANNESS_CONFIG_REPLACE_BUILTINS
///
#macro ENDIANNESS_CONFIG_REPLACE_BUILTINS true

///
/// Configuration option that dictates whether the op codes for the built-in functions should be
/// validated or not (i.e validate that the EndiannessBuiltInOpCodes enum has the correct values).
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_OPCODES
///
#macro ENDIANNESS_CONFIG_VALIDATE_OPCODES true

///
/// Configuration option that dictates whether the endianness swapping functions should be
/// validated or not.
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_SWAP
///
#macro ENDIANNESS_CONFIG_VALIDATE_SWAP true

///
/// Configuration option that dictates whether the endianness fixing logic should be validated or
/// not.
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_FIX
///
#macro ENDIANNESS_CONFIG_VALIDATE_FIX true

///
/// Configuration option that dictates whether the extended data types should be validated or not.
/// This specifically validates that the extended data types decode into the native data types
/// correctly.
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_TYPES
///
#macro ENDIANNESS_CONFIG_VALIDATE_TYPES true

///
/// Configuration option that dictates whether the extension functions should be validated or not.
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_EXTENSIONS
///
#macro ENDIANNESS_CONFIG_VALIDATE_EXTENSIONS true

///
/// Configuration option that dictates whether the replacement of the built-in functions should be
/// validated or not.
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_REPLACEMENT
///
#macro ENDIANNESS_CONFIG_VALIDATE_REPLACEMENT true

#endregion Configuration
#region Code Injection
///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
// GameMaker allows us to define macros, which provide us with text replacement functionalities  //
// prior to the final compilation of the game. We leverage this to define macros with the names  //
// of the built-in functions we want to replace. This effectively means that whenever GameMaker  //
// encounters the built-in function in the code it will replace it according to our macro.       //
//                                                                                               //
// This mechanism allows us to seemlessly replace the built-in function by our custom code,      //
// however we still need to be able to execute the built-in functions. Unfortunately, since we   //
// defined the macros that always replace the built-in functions by our custom ones we cannot    //
// simply invoke them like we normally would. Luckily, GameMaker uses indexes as an abstraction  //
// for most things and built-in functions are no exception. Therefore, if we know the index of a //
// given built-in function we can setup a variable with it and then invoke the built-in function //
// just as if we were invoking a method/script referenced in a regular variable.                 //
//                                                                                               //
// The EndiannessBuiltInOpCodes enum is used for storing the indexes (here mentioned as op       //
// codes) for each one of the built-in functions we need to replace. There are then a set of     //
// macros and global variables that allow us to reference the built-in function by using one of  //
// builtin_* macros as if it were the equivalent built-in function.                              //
//                                                                                               //
// Note however that these op codes could change between any GameMaker release (potentially even //
// between target platforms, although that hasn't been encountered during our tests). This would //
// lead to (potentially) the wrong built-in functions being referenced. If that happens then it  //
// is highly likely that a "random" error is thrown whenever a built-in function is accessed. In //
// order to fix this we just need to update the op codes in the enum, the mechanism for which is //
// detailed in the comment above the macros redefining the built-in functions below.             //
//                                                                                               //
// Therefore, it is highly recommended that the automated validations of these extension         //
// mechanisms are kept enabled at least during development. This way any divergence between the  //
// stored op-codes (or even any other behaviour in these extensions) can be caught early on and  //
// addressed accordingly.                                                                        //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

///
/// Enumeration of the different op codes for the replaced built-in functions.
///
enum EndiannessBuiltInOpCodes {
  BufferFill  = 1508,
  BufferPeek  = 1492,
  BufferPoke  = 1491,
  BufferRead  = 1490,
  BufferWrite = 1489,
}

/*
  Comment out these macros and run the following code to get the updated op codes:

    show_debug_message(@"
      enum EndiannessBuiltInOpCodes {
        BufferFill  = " + string(buffer_fill)  + @",
        BufferPeek  = " + string(buffer_peek)  + @",
        BufferPoke  = " + string(buffer_poke)  + @",
        BufferRead  = " + string(buffer_read)  + @",
        BufferWrite = " + string(buffer_write) + @",
      }
    ");
*/
#macro buffer_fill  (ENDIANNESS_CONFIG_REPLACE_BUILTINS ? buffer_fill_ext  : builtin_buffer_fill)
#macro buffer_peek  (ENDIANNESS_CONFIG_REPLACE_BUILTINS ? buffer_peek_ext  : builtin_buffer_peek)
#macro buffer_poke  (ENDIANNESS_CONFIG_REPLACE_BUILTINS ? buffer_poke_ext  : builtin_buffer_poke)
#macro buffer_read  (ENDIANNESS_CONFIG_REPLACE_BUILTINS ? buffer_read_ext  : builtin_buffer_read)
#macro buffer_write (ENDIANNESS_CONFIG_REPLACE_BUILTINS ? buffer_write_ext : builtin_buffer_write)

///
/// Executes the built-in buffer_fill function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process.
///
/// @function builtin_buffer_fill
/// @param {Buffer} buffer
///   The index of the buffer to fill.
/// @param {Integer} offset
///   The data offset value (in bytes).
/// @param {Integer} type
///   The type of data that is to be written to the buffer (note: cannot be one of the extended
///   types).
/// @param {*} value
///   The data to write.
/// @param {Integer} size
///   The size of the buffer (in bytes) that you wish to fill.
///
#macro builtin_buffer_fill global.__buffer_fill__
builtin_buffer_fill = EndiannessBuiltInOpCodes.BufferFill;

///
/// Executes the built-in buffer_peek function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process.
///
/// @function builtin_buffer_peek
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} offset
///   The offset position (in bytes) within the buffer to read the given data from.
/// @param {Integer} type
///   The type of data that is to be read from the buffer (note: cannot be one of the extended
///   types).
/// @returns {*}
///   The value read.
///
#macro builtin_buffer_peek global.__buffer_peek__
builtin_buffer_peek = EndiannessBuiltInOpCodes.BufferPeek;

///
/// Executes the built-in buffer_poke function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process.
///
/// @function builtin_buffer_poke
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} offset
///   The offset position (in bytes) within the buffer to write the given data to.
/// @param {Integer} type
///   The type of data that is to be written to the buffer (note: cannot be one of the extended
///   types).
/// @param {*} value
///   The data to add to the buffer, in accordance with the type specified.
///
#macro builtin_buffer_poke global.__buffer_poke__
builtin_buffer_poke = EndiannessBuiltInOpCodes.BufferPoke;

///
/// Executes the built-in buffer_read function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process.
///
/// @function builtin_buffer_read
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} type
///   The type of data that is to be read from the buffer (note: cannot be one of the extended
///   types).
/// @returns {*}
///   The value read.
///
#macro builtin_buffer_read global.__buffer_read__
builtin_buffer_read = EndiannessBuiltInOpCodes.BufferRead;

///
/// Executes the built-in buffer_write function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process.
///
/// @function builtin_buffer_write
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} type
///   The type of data that is to be written to the buffer (note: cannot be one of the extended
///   types).
/// @param {*} value
///   The data to write.
///
#macro builtin_buffer_write global.__buffer_write__
builtin_buffer_write = EndiannessBuiltInOpCodes.BufferWrite;

#endregion Code Injection
#region Extension Code
// TODO: Handle floating point endianness

///
/// An unsigned 16-bit integer stored in big-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_u16be
///
#macro buffer_u16be (0x8b160000 | buffer_u16)

///
/// An unsigned 16-bit integer stored in little-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_u16le
///
#macro buffer_u16le (0x81160000 | buffer_u16)

///
/// A signed 16-bit integer stored in big-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_s16be
///
#macro buffer_s16be (0x1b160000 | buffer_s16)

///
/// A signed 16-bit integer stored in little-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_s16le
///
#macro buffer_s16le (0x11160000 | buffer_s16)

///
/// An unsigned 32-bit integer stored in big-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_u32be
///
#macro buffer_u32be (0x8b320000 | buffer_u32)

///
/// An unsigned 32-bit integer stored in little-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_u32le
///
#macro buffer_u32le (0x81320000 | buffer_u32)

///
/// A signed 32-bit integer stored in big-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_s32be
///
#macro buffer_s32be (0x1b320000 | buffer_s32)

///
/// A signed 32-bit integer stored in little-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_s32le
///
#macro buffer_s32le (0x11320000 | buffer_s32)

///
/// An unsigned 64-bit integer stored in big-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_u64be
///
#macro buffer_u64be (0x8b640000 | buffer_u64)

///
/// An unsigned 64-bit integer stored in little-endian format.
///
/// If the built-in functions are being replaced by the extended versions then you can seemlessly
/// use this type with the built-in functions, otherwise this type is only recognized by the
/// extended versions.
///
/// @constant {Integer} buffer_u64le
///
#macro buffer_u64le (0x81640000 | buffer_u64)


///
/// Checks if the current platform performs the native operations in little-endian format.
///
/// @function is_native_little_endian
/// @returns {Bool}
///   True if the native operations are performed in little-endian format or false otherwise.
///
function is_native_little_endian() {
  static memoized_value = (function() {
    var buffer = buffer_create(2, buffer_fixed, 1);
    try {
      builtin_buffer_write(buffer, buffer_u16, 0x0005);

      var first_byte = builtin_buffer_peek(buffer, 0, buffer_u8);
      return first_byte == 0x05;
    } finally {
      buffer_delete(buffer);
    }
  })();
  return memoized_value;
};

///
/// Fills a previously created buffer with a given data type and value, allowing for the usage of
/// endianness-aware versions of the data types.
///
/// @function buffer_fill_ext
/// @param {Buffer} buffer
///   The index of the buffer to fill.
/// @param {Integer} offset
///   The data offset value (in bytes).
/// @param {Integer} type
///   The type of data that is to be written to the buffer.
/// @param {*} value
///   The data to write.
/// @param {Integer} size
///   The size of the buffer (in bytes) that you wish to fill.
///
function buffer_fill_ext(buffer, offset, type, value, size) {
  return builtin_buffer_fill(buffer, offset, type & 0xffff, fix_endianness(type, value), size);
}

///
/// Reads a piece of data from the given buffer without modifying the current seek position,
/// allowing for the usage of endianness-aware versions of the data types.
///
/// @function buffer_peek_ext
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} offset
///   The offset position (in bytes) within the buffer to read the given data from.
/// @param {Integer} type
///   The type of data that is to be read from the buffer.
/// @returns {*}
///   The value read.
///
function buffer_peek_ext(buffer, offset, type) {
  return fix_endianness(type, builtin_buffer_peek(buffer, offset, type & 0xffff));
}

///
/// Writes a piece of data to the given buffer without modifying the current seek position,
/// allowing for the usage of endianness-aware versions of the data types.
///
/// @function buffer_poke_ext
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} offset
///   The offset position (in bytes) within the buffer to write the given data to.
/// @param {Integer} type
///   The type of data that is to be written to the buffer.
/// @param {*} value
///   The data to add to the buffer, in accordance with the type specified.
///
function buffer_poke_ext(buffer, offset, type, value) {
  return builtin_buffer_poke(buffer, offset, type & 0xffff, fix_endianness(type, value));
}

///
/// Reads a piece of data from the given buffer, allowing for the usage of endianness-aware
/// versions of the data types.
///
/// @function buffer_read_ext
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} type
///   The type of data that is to be read from the buffer.
/// @returns {*}
///   The value read.
///
function buffer_read_ext(buffer, type) {
  return fix_endianness(type, builtin_buffer_read(buffer, type & 0xffff));
}

///
/// Executes the built-in buffer_write function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process.
///
/// @function buffer_write_ext
/// @param {Buffer} buffer
///   The index of the buffer to use.
/// @param {Integer} type
///   The type of data that is to be written to the buffer (note: cannot be one of the extended
///   types).
/// @param {*} value
///   The data to write.
///
function buffer_write_ext(buffer, type, value) {
  return builtin_buffer_write(buffer, type & 0xffff, fix_endianness(type, value));
}

///
/// Returns the supplied value with any endianness fixes applied in order for the native endianness
/// to produce the desired endianness, even if differing.
///
/// @function fix_endianness
/// @param {Integer} type
///   The data type.
/// @param {*} value
///   The value to fix.
/// @returns {*}
///   The (potentially) fixed value.
///
function fix_endianness(type, value) {
  if (is_native_little_endian()) {
    switch (type) {
      case buffer_u16be:
      case buffer_s16be:
        return swap_endianness_16(value);
      case buffer_u32be:
      case buffer_s32be:
        return swap_endianness_32(value);
      case buffer_u64be:
        return swap_endianness_64(value);
    }
  } else {
    switch (type) {
      case buffer_u16le:
      case buffer_s16le:
        return swap_endianness_16(value);
      case buffer_u32le:
      case buffer_s32le:
        return swap_endianness_32(value);
      case buffer_u64le:
        return swap_endianness_64(value);
    }
  }
  return value;
}


///
/// Swaps the endianness of a 16-bit integer.
///
/// @function swap_endianness_16
/// @param {Integer} value
///   The integer to swap endianness.
/// @returns {Integer}
///   The supplied integer in the reverse endianness.
///
function swap_endianness_16(value) {
  return ((value << 8) & 0xff00)
       | ((value >> 8) & 0x00ff);
}

///
/// Swaps the endianness of a 32-bit integer.
///
/// @function swap_endianness_32
/// @param {Integer} value
///   The integer to swap endianness.
/// @returns {Integer}
///   The supplied integer in the reverse endianness.
///
function swap_endianness_32(value) {
  return ((value << 24) & 0xff000000)
       | ((value >> 24) & 0x000000ff)
       | ((value <<  8) & 0x00ff0000)
       | ((value >>  8) & 0x0000ff00);
}

///
/// Swaps the endianness of a 64-bit integer.
///
/// @function swap_endianness_64
/// @param {Integer} value
///   The integer to swap endianness.
/// @returns {Integer}
///   The supplied integer in the reverse endianness.
///
function swap_endianness_64(value) {
  return ((value << 56) & 0xff00000000000000)
       | ((value >> 56) & 0x00000000000000ff)
       | ((value << 40) & 0x00ff000000000000)
       | ((value >> 40) & 0x000000000000ff00)
       | ((value << 24) & 0x0000ff0000000000)
       | ((value >> 24) & 0x0000000000ff0000)
       | ((value <<  8) & 0x000000ff00000000)
       | ((value >>  8) & 0x00000000ff000000);
}

#endregion Extension Code
#region Validation

if (ENDIANNESS_CONFIG_VALIDATE_OPCODES) {
  var buffer = buffer_create(4, buffer_fixed, 1);
  try {
    for (var i = 1; i <= 4; i++) {
      if (builtin_buffer_write(buffer, buffer_u8, i) < -1)
        throw "buffer_write - failed to write a byte to the buffer (byte " + string(i) + ")";
    }

    buffer_seek(buffer, buffer_seek_start, 0);
    for (var i = 1; i <= 4; i++) {
      var byte = builtin_buffer_read(buffer, buffer_u8);
      if (byte != i)
        throw "buffer_read - failed to read a byte from the buffer (got " + string(byte)
            + " but wanted " + string(i) + ")";
    }

    builtin_buffer_poke(buffer, 1, buffer_u8, 10);
    if (builtin_buffer_peek(buffer, 1, buffer_u8) != 10)
      throw "buffer_peek/poke - failed to write & read byte 10 at offset 1 in the buffer";

    builtin_buffer_fill(buffer, 0, buffer_u8, 111, 4);
    buffer_seek(buffer, buffer_seek_start, 0);
    repeat (4) {
      if (builtin_buffer_read(buffer, buffer_u8) != 111)
        throw "buffer_fill - failed to fill buffer with byte 111";
    }
  } catch (error) {
    throw "At least one op code in EndiannessBuiltInOpCodes is incorrect:\n\n" + string(error);
  } finally {
    buffer_delete(buffer);
  }
}

if (ENDIANNESS_CONFIG_VALIDATE_SWAP) {
  if (swap_endianness_16(0xffee) != 0xeeff)
    throw "swap_endianness_16: did not swap endianness correctly";
  if (swap_endianness_32(0xffeeddcc) != 0xccddeeff)
    throw "swap_endianness_32: did not swap endianness correctly";
  if (swap_endianness_64(0xffeeddccbbaa9988) != 0x8899aabbccddeeff)
    throw "swap_endianness_64: did not swap endianness correctly";
}

if (ENDIANNESS_CONFIG_VALIDATE_TYPES) {
  if ((buffer_u16 & 0xffff) != buffer_u16)
    throw "buffer_u16be, buffer_u16le: type does not decode correctly";
  if ((buffer_s16 & 0xffff) != buffer_s16)
    throw "buffer_s16be, buffer_s16le: type does not decode correctly";
  if ((buffer_u32 & 0xffff) != buffer_u32)
    throw "buffer_u32be, buffer_u32le: type does not decode correctly";
  if ((buffer_s32 & 0xffff) != buffer_s32)
    throw "buffer_s32be, buffer_s32le: type does not decode correctly";
  if ((buffer_u64 & 0xffff) != buffer_u64)
    throw "buffer_u64be, buffer_u64le: type does not decode correctly";
}

if (ENDIANNESS_CONFIG_VALIDATE_FIX) {
  if (is_native_little_endian()) {
    if (fix_endianness(buffer_u16be, 0x1234) != 0x3412)
      throw "fix_endianness(buffer_u16be): did not swap BE in a LE environment";
    if (fix_endianness(buffer_u16le, 0x1234) != 0x1234)
      throw "fix_endianness(buffer_u16le): swapped LE in a LE environment";
    if (fix_endianness(buffer_s16be, 0x1234) != 0x3412)
      throw "fix_endianness(buffer_s16be): did not swap BE in a LE environment";
    if (fix_endianness(buffer_s16le, 0x1234) != 0x1234)
      throw "fix_endianness(buffer_s16le): swapped LE in a LE environment";
    if (fix_endianness(buffer_u32be, 0x12345678) != 0x78563412)
      throw "fix_endianness(buffer_u32be): did not swap BE in a LE environment";
    if (fix_endianness(buffer_u32le, 0x12345678) != 0x12345678)
      throw "fix_endianness(buffer_u32le): swapped LE in a LE environment";
    if (fix_endianness(buffer_s32be, 0x12345678) != 0x78563412)
      throw "fix_endianness(buffer_s32be): did not swap BE in a LE environment";
    if (fix_endianness(buffer_s32le, 0x12345678) != 0x12345678)
      throw "fix_endianness(buffer_s32le): swapped LE in a LE environment";
    if (fix_endianness(buffer_u64be, 0x123456789abcdef0) != 0xf0debc9a78563412)
      throw "fix_endianness(buffer_u64be): did not swap BE in a LE environment";
    if (fix_endianness(buffer_u64le, 0x123456789abcdef0) != 0x123456789abcdef0)
      throw "fix_endianness(buffer_u64le): swapped LE in a LE environment";
  } else {
    if (fix_endianness(buffer_u16be, 0x1234) != 0x1234)
      throw "fix_endianness(buffer_u16be): swapped BE in a BE environment";
    if (fix_endianness(buffer_u16le, 0x1234) != 0x3412)
      throw "fix_endianness(buffer_u16le): did not swap LE in a BE environment";
    if (fix_endianness(buffer_s16be, 0x1234) != 0x1234)
      throw "fix_endianness(buffer_s16be): swapped BE in a BE environment";
    if (fix_endianness(buffer_s16le, 0x1234) != 0x3412)
      throw "fix_endianness(buffer_s16le): did not swap LE in a BE environment";
    if (fix_endianness(buffer_u32be, 0x12345678) != 0x12345678)
      throw "fix_endianness(buffer_u32be): swapped BE in a BE environment";
    if (fix_endianness(buffer_u32le, 0x12345678) != 0x78563412)
      throw "fix_endianness(buffer_u32le): did not swap LE in a BE environment";
    if (fix_endianness(buffer_s32be, 0x12345678) != 0x12345678)
      throw "fix_endianness(buffer_s32be): swapped BE in a BE environment";
    if (fix_endianness(buffer_s32le, 0x12345678) != 0x78563412)
      throw "fix_endianness(buffer_s32le): did not swap LE in a BE environment";
    if (fix_endianness(buffer_u64be, 0x123456789abcdef0) != 0x123456789abcdef0)
      throw "fix_endianness(buffer_u64be): swapped BE in a BE environment";
    if (fix_endianness(buffer_u64le, 0x123456789abcdef0) != 0xf0debc9a78563412)
      throw "fix_endianness(buffer_u64le): did not swap LE in a BE environment";
  }
  if (fix_endianness(buffer_u8, 0x12) != 0x12)
    throw "fix_endianness(buffer_u8): swapped native type";
  if (fix_endianness(buffer_s8, 0x12) != 0x12)
    throw "fix_endianness(buffer_s8): swapped native type";
  if (fix_endianness(buffer_u16, 0x1234) != 0x1234)
    throw "fix_endianness(buffer_u16): swapped native type";
  if (fix_endianness(buffer_s16, 0x1234) != 0x1234)
    throw "fix_endianness(buffer_s16): swapped native type";
  if (fix_endianness(buffer_u32, 0x12345678) != 0x12345678)
    throw "fix_endianness(buffer_u32): swapped native type";
  if (fix_endianness(buffer_s32, 0x12345678) != 0x12345678)
    throw "fix_endianness(buffer_s32): swapped native type";
  if (fix_endianness(buffer_u64, 0x123456789abcdef0) != 0x123456789abcdef0)
    throw "fix_endianness(buffer_u64): swapped native type";
  if (fix_endianness(buffer_f16, 1.234) != 1.234)
    throw "fix_endianness(buffer_f16): swapped native type";
  if (fix_endianness(buffer_f32, 1.234) != 1.234)
    throw "fix_endianness(buffer_f32): swapped native type";
  if (fix_endianness(buffer_f64, 1.234) != 1.234)
    throw "fix_endianness(buffer_f64): swapped native type";
  if (fix_endianness(buffer_bool, true) != true)
    throw "fix_endianness(buffer_bool): swapped native type";
  if (fix_endianness(buffer_string, "Hello") != "Hello")
    throw "fix_endianness(buffer_string): swapped native type";
  if (fix_endianness(buffer_text, "Hello") != "Hello")
    throw "fix_endianness(buffer_text): swapped native type";
}

if (ENDIANNESS_CONFIG_VALIDATE_EXTENSIONS) {
  var actual, bytes, buffer = buffer_create(8, buffer_fixed, 1);
  try {
    buffer_fill_ext(buffer, 0, buffer_u32be, 0x11223344, 8);
    bytes = [ 0x11, 0x22, 0x33, 0x44, 0x11, 0x22, 0x33, 0x44 ];
    for (var i = 0; i < 8; i++) {
      actual = builtin_buffer_peek(buffer, i, buffer_u8);
      if (actual != bytes[i]) {
        throw "buffer_fill_ext(be): did not fill the buffer correctly, expected byte " + string(i)
            + " to be " + string(bytes[i]) + " but was " + string(actual);
      }
    }

    buffer_fill_ext(buffer, 0, buffer_u32le, 0x11223344, 8);
    bytes = [ 0x44, 0x33, 0x22, 0x11, 0x44, 0x33, 0x22, 0x11 ];
    for (var i = 0; i < 8; i++) {
      actual = builtin_buffer_peek(buffer, i, buffer_u8);
      if (actual != bytes[i]) {
        throw "buffer_fill_ext(le): did not fill the buffer correctly, expected byte " + string(i)
            + " to be " + string(bytes[i]) + " but was " + string(actual);
      }
    }

    actual = buffer_peek_ext(buffer, 2, buffer_u32be);
    if (actual != 0x22114433)
      throw "buffer_peek_ext(be): did not peek the buffer correctly (" + string(actual) + ")";

    actual = buffer_peek_ext(buffer, 2, buffer_u32le);
    if (actual != 0x33441122)
      throw "buffer_peek_ext(le): did not peek the buffer correctly (" + string(actual) + ")";

    buffer_poke_ext(buffer, 2, buffer_u32be, 0xaabbccdd);
    bytes = [ 0x44, 0x33, 0xaa, 0xbb, 0xcc, 0xdd, 0x22, 0x11 ];
    for (var i = 0; i < 8; i++) {
      actual = builtin_buffer_peek(buffer, i, buffer_u8);
      if (actual != bytes[i]) {
        throw "buffer_poke_ext(be): did not poke the buffer correctly, expected byte " + string(i)
            + " to be " + string(bytes[i]) + " but was " + string(actual);
      }
    }

    buffer_poke_ext(buffer, 2, buffer_u32le, 0xaabbccdd);
    bytes = [ 0x44, 0x33, 0xdd, 0xcc, 0xbb, 0xaa, 0x22, 0x11 ];
    for (var i = 0; i < 8; i++) {
      actual = builtin_buffer_peek(buffer, i, buffer_u8);
      if (actual != bytes[i]) {
        throw "buffer_poke_ext(le): did not poke the buffer correctly, expected byte " + string(i)
            + " to be " + string(bytes[i]) + " but was " + string(actual);
      }
    }

    buffer_seek(buffer, buffer_seek_start, 0);
    buffer_write_ext(buffer, buffer_u64be, 0x1122334455667788);
    bytes = [ 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88 ];
    for (var i = 0; i < 8; i++) {
      actual = builtin_buffer_peek(buffer, i, buffer_u8);
      if (actual != bytes[i]) {
        throw "buffer_write_ext(be): did not write the buffer correctly, expected byte "
            + string(i) + " to be " + string(bytes[i]) + " but was " + string(actual);
      }
    }

    buffer_seek(buffer, buffer_seek_start, 0);
    buffer_write_ext(buffer, buffer_u64le, 0x1122334455667788);
    bytes = [ 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11 ];
    for (var i = 0; i < 8; i++) {
      actual = builtin_buffer_peek(buffer, i, buffer_u8);
      if (actual != bytes[i]) {
        throw "buffer_write_ext(le): did not write the buffer correctly, expected byte "
            + string(i) + " to be " + string(bytes[i]) + " but was " + string(actual);
      }
    }

    buffer_seek(buffer, buffer_seek_start, 0);
    actual = buffer_read_ext(buffer, buffer_u64be);
    if (actual != 0x8877665544332211)
      throw "buffer_read_ext(be): did not read the buffer correctly (" + string(actual) + ")";

    buffer_seek(buffer, buffer_seek_start, 0);
    actual = buffer_read_ext(buffer, buffer_u64le);
    if (actual != 0x1122334455667788)
      throw "buffer_read_ext(le): did not read the buffer correctly (" + string(actual) + ")";
  } finally {
    buffer_delete(buffer);
  }
}

if (ENDIANNESS_CONFIG_VALIDATE_REPLACEMENT) {
  if (ENDIANNESS_CONFIG_REPLACE_BUILTINS) {
    if (buffer_fill != buffer_fill_ext)
      throw "buffer_fill was not correctly replaced";
    if (buffer_peek != buffer_peek_ext)
      throw "buffer_peek was not correctly replaced";
    if (buffer_poke != buffer_poke_ext)
      throw "buffer_poke was not correctly replaced";
    if (buffer_read != buffer_read_ext)
      throw "buffer_read was not correctly replaced";
    if (buffer_write != buffer_write_ext)
      throw "buffer_write was not correctly replaced";
  } else {
    if (buffer_fill != EndiannessBuiltInOpCodes.BufferFill)
      throw "buffer_fill is not the built-in";
    if (buffer_peek != EndiannessBuiltInOpCodes.BufferPeek)
      throw "buffer_peek is not the built-in";
    if (buffer_poke != EndiannessBuiltInOpCodes.BufferPoke)
      throw "buffer_poke is not the built-in";
    if (buffer_read != EndiannessBuiltInOpCodes.BufferRead)
      throw "buffer_read is not the built-in";
    if (buffer_write != EndiannessBuiltInOpCodes.BufferWrite)
      throw "buffer_write is not the built-in";
  }
}

#endregion Validation
