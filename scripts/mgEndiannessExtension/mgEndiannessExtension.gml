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
// TODO: To be implemented
#endregion Configuration
#region Code Injection
// TODO: To be implemented
#endregion Code Injection
#region Extension Code
// TODO: To be implemented
#endregion Extension Code
#region Validation
// TODO: To be implemented
#endregion Validation
