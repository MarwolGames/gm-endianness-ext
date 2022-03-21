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
      macros are meant to be overridden by the user on a configuration-specific basis in order to
      configure the behaviour based on different targets, build types, etc. Due to this, the
      default values attempt to provide the most developer-centric experience.

    - Code Injection: the set of macros responsible for providing the code injection capabilities
      of these code extensions. The section comment explains in detail how the mechanism works so
      that the user can correct any potential issues without being dependent on a new version of
      the extension being released.

    - Extension Code: all of the code pertaining to the implementation of these code extensions
      that does not fall into one of the other regions.

    - Validation: a collection of self-contained, automated tests that assure the user of the
      correctness of their configuration.

  For any improvements, suggestions or bug reports please reach out to us.

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

#endregion Configuration
#region Code Injection
// TODO: Section comment

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
///       integer would not go through the coercion process. Therefore we use a globalvar
///       declaration instead of a #macro declaration since both create the same identifier but the
///       former allows us to actually invoke the built-in function.
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
globalvar builtin_buffer_fill;
builtin_buffer_fill = EndiannessBuiltInOpCodes.BufferFill;

///
/// Executes the built-in buffer_peek function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process. Therefore we use a globalvar
///       declaration instead of a #macro declaration since both create the same identifier but the
///       former allows us to actually invoke the built-in function.
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
globalvar builtin_buffer_peek;
builtin_buffer_peek = EndiannessBuiltInOpCodes.BufferPeek;

///
/// Executes the built-in buffer_poke function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process. Therefore we use a globalvar
///       declaration instead of a #macro declaration since both create the same identifier but the
///       former allows us to actually invoke the built-in function.
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
globalvar builtin_buffer_poke;
builtin_buffer_poke = EndiannessBuiltInOpCodes.BufferPoke;

///
/// Executes the built-in buffer_read function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process. Therefore we use a globalvar
///       declaration instead of a #macro declaration since both create the same identifier but the
///       former allows us to actually invoke the built-in function.
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
globalvar builtin_buffer_read;
builtin_buffer_read = EndiannessBuiltInOpCodes.BufferRead;

///
/// Executes the built-in buffer_write function, regardless of whether the built-in function has
/// been replaced by the extended version or not.
///
/// Note: this needs to be stored in a variable. If GameMaker encounters a variable with an integer
///       that is being used as a function invocation then it will coerce the integer to a function
///       (interpreting the integer as the function/script/method index). However, if we tried to
///       invoke the integer as a function directly then we'd get a runtime exception as the
///       integer would not go through the coercion process. Therefore we use a globalvar
///       declaration instead of a #macro declaration since both create the same identifier but the
///       former allows us to actually invoke the built-in function.
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
globalvar builtin_buffer_write;
builtin_buffer_write = EndiannessBuiltInOpCodes.BufferWrite;

#endregion Code Injection
#region Extension Code

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
  show_debug_message("EndiannessBuiltInOpCodes: opcodes are correct");
}

if (ENDIANNESS_CONFIG_VALIDATE_SWAP) {
  if (swap_endianness_16(0xffee) != 0xeeff)
    throw "swap_endianness_16: did not swap endianness correctly";
  if (swap_endianness_32(0xffeeddcc) != 0xccddeeff)
    throw "swap_endianness_32: did not swap endianness correctly";
  if (swap_endianness_64(0xffeeddccbbaa9988) != 0x8899aabbccddeeff)
    throw "swap_endianness_64: did not swap endianness correctly";
}

#endregion Validation
