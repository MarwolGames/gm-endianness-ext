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
/// Note that this configuration option is only relevant if the built-in functions are not being
/// replaced. This comes from the fact that we cannot retrieve the correct op code for the built-in
/// functions when they are replaced, so even if we could validate the correctness of the
/// configured op codes indirectly (e.g. by running the functions and validating their side
/// effects) we still wouldn't be able to tell the user what the correct op codes were.
///
/// By default this is enabled so that potential errors in the extension code are reported as soon
/// as possible.
///
/// @constant {Bool} ENDIANNESS_CONFIG_VALIDATE_OPCODES
///
#macro ENDIANNESS_CONFIG_VALIDATE_OPCODES true

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

// TODO: code injection
#endregion Code Injection
#region Extension Code
// TODO: To be implemented
#endregion Extension Code
#region Validation

if (!ENDIANNESS_CONFIG_REPLACE_BUILTINS) {

  if (ENDIANNESS_CONFIG_VALIDATE_OPCODES) {
    var opcodes_are_correct = true;
    opcodes_are_correct &= buffer_fill  == EndiannessBuiltInOpCodes.BufferFill;
    opcodes_are_correct &= buffer_peek  == EndiannessBuiltInOpCodes.BufferPeek;
    opcodes_are_correct &= buffer_poke  == EndiannessBuiltInOpCodes.BufferPoke;
    opcodes_are_correct &= buffer_read  == EndiannessBuiltInOpCodes.BufferRead;
    opcodes_are_correct &= buffer_write == EndiannessBuiltInOpCodes.BufferWrite;
    if (!opcodes_are_correct) {
      var opcodes = @"
        enum EndiannessBuiltInOpCodes {
          BufferFill  = " + string(buffer_fill)  + @",
          BufferPeek  = " + string(buffer_peek)  + @",
          BufferPoke  = " + string(buffer_poke)  + @",
          BufferRead  = " + string(buffer_read)  + @",
          BufferWrite = " + string(buffer_write) + @",
        }
      ";
      throw "One of more op codes in EndiannessBuiltInOpCodes are incorrect.\n"
          + "Please update the enum with the following:\n" + opcodes;
    }
  }

}

#endregion Validation
