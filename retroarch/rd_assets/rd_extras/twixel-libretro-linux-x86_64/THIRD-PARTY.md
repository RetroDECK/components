# Third-party software

Twixel is licensed under GPL-3.0-or-later with the additional permission in
[LICENSE-EXCEPTION.md](LICENSE-EXCEPTION.md). It embeds the third-party components below, all under
permissive licenses or in the public domain (the AppImage runtime, which the Linux AppImages carry
next to Twixel, also contains code under the LGPL-2.1: see below). Binary distributions (the libretro core, the SDL app,
packages, the Android APK) must ship this file, or the notices it contains, together with the binaries.

Each vendored folder under `deps/` also keeps its own `LICENSE` file.

| Component | Version | License | Used in | Notice |
|---|---|---|---|---|
| [dr_mp3](https://github.com/mackron/dr_libs) (dr_libs), based on minimp3 | 0.7.4 | `Unlicense OR MIT-0` | MP3 decoding (`drmp3dec_decode_frame` only) | no attribution required; [deps/dr_libs/LICENSE](deps/dr_libs/LICENSE) |
| [miniz](https://github.com/richgel999/miniz) | 11.3.2 | `MIT` | zip archives, inflate | full text below |
| [cJSON](https://github.com/DaveGamble/cJSON) | 1.7.19 | `MIT` | `metadata.json` | full text below |
| [stb_image](https://github.com/nothings/stb) | 2.30 | `MIT OR Unlicense` | PNG assets, JPEG/PNG covers | [deps/stb/LICENSE](deps/stb/LICENSE) (MIT text below) |
| [stb_truetype](https://github.com/nothings/stb) | 1.26 | `MIT OR Unlicense` | text rendering | [deps/stb/LICENSE](deps/stb/LICENSE) (MIT text below) |
| [libretro.h](https://github.com/libretro/RetroArch) | RetroArch API header | `MIT` | the libretro core and its test harness | full text below |
| [Montserrat](https://github.com/JulietaUla/Montserrat) | static TTFs (SemiBold, Bold, ExtraBold) | `OFL-1.1` | the embedded UI font | [assets/fonts/OFL.txt](assets/fonts/OFL.txt) |
| [Noto Sans](https://github.com/notofonts/latin-greek-cyrillic) | subsets (Greek block) of the variable font at weights 600 and 800, Google Fonts commit 9710da1 | `OFL-1.1` | fallback font for Greek | [assets/fonts/subsets/OFL-NotoSans.txt](assets/fonts/subsets/OFL-NotoSans.txt) |
| [Noto Sans JP, KR, SC, TC](https://github.com/notofonts/noto-cjk) | subsets (the characters Twixel writes) of the variable fonts at weights 600 and 800, Google Fonts commit 9710da1 | `OFL-1.1` | fallback fonts for Japanese, Korean and Chinese | [assets/fonts/subsets/OFL-NotoSansCJK.txt](assets/fonts/subsets/OFL-NotoSansCJK.txt) |
| [SDL3](https://libsdl.org/) | 3.4.x (3.4.16 in the packages) | `Zlib` | the SDL app, linked as a shared library (not vendored in the source tree). The binary packages bundle SDL 3.4.16: the Android APK ships `libSDL3.so` and SDL's `org.libsdl.app` Java classes, built from the source fetched by `frontends/android/fetch-sdl.sh`; the macOS app bundles a universal `libSDL3.0.dylib` and the Linux archive and AppImage `libSDL3.so.0`, all built from that source (`packaging/`), and the Flatpak bundle a `libSDL3.so.0` built from the same release with the freedesktop SDK (`packaging/flatpak/`); the Windows x86_64 zip ships the official release `SDL3.dll`, and the Windows ARM64 zip an `SDL3.dll` built from that source with llvm-mingw (SDL publishes no mingw build for ARM64) | full text below |
| [mingw-w64](https://www.mingw-w64.org/) runtime | as shipped with the compilers of the packages: Debian's mingw-w64 (x86_64), llvm-mingw 20260922 (ARM64) | `ZPL-2.1` and other permissive licenses (some parts in the public domain) | the Windows binaries only: the compilers link its startup code and parts of its C library into every Windows program and DLL (the core, `twixel.exe`, and the ARM64 `SDL3.dll`; the official x86_64 `SDL3.dll`, built by the SDL project with mingw-w64, holds it too). Not part of the source tree | the Windows packages carry the toolchain's own notice file as `licenses/mingw-w64-runtime.txt` |
| [AppImage runtime](https://github.com/AppImage/type2-runtime) (type2-runtime) | release 20251108, put in place by [appimagetool](https://github.com/AppImage/appimagetool) 1.9.1 (a build tool, not shipped) | `MIT`; it is a static program with code from musl 1.2.5 (`MIT`), libfuse 3.15.0 (`LGPL-2.1-or-later`), squashfuse 0.5.2 (`BSD-2-Clause`), Zstandard (`BSD-3-Clause`), zlib 1.3.1 (`Zlib`) and mimalloc 2.1.7 (`MIT`) | the Linux AppImages only: the small program at the start of every AppImage that mounts (or unpacks) it and starts Twixel; it is not linked with Twixel. Not part of the source tree | [packaging/appimage/runtime-licenses.txt](packaging/appimage/runtime-licenses.txt), shipped in every AppImage as `usr/share/doc/twixel/licenses/AppImage-runtime.txt` |
| [Gradle Wrapper](https://gradle.org/) | 9.5.1 | `Apache-2.0` | build tooling of the Android app only (`frontends/android/gradlew`, `gradlew.bat`, `gradle/wrapper/`); not part of any binary | [apache.org/licenses/LICENSE-2.0](https://www.apache.org/licenses/LICENSE-2.0) |

The compilers also link a little support code of their own into the binaries: GCC's `libgcc` in the
Windows x86_64 builds (GPL-3.0 with the GCC Runtime Library Exception) and LLVM's `compiler-rt`
built-ins in the Windows ARM64 builds (Apache-2.0 with the LLVM Exception). Neither license asks for a
notice in a binary distribution of a program compiled with them.

Because the AppImage runtime contains libfuse, under the LGPL-2.1, whoever distributes Twixel
AppImages must also offer the corresponding source of libfuse and of the runtime, with the means to
relink it (LGPL-2.1 section 6), for example the source archives named in
[packaging/appimage/runtime-licenses.txt](packaging/appimage/runtime-licenses.txt) published next to
the AppImages. The Flatpak bundles hold only Twixel and SDL3; the freedesktop runtime they run on is
installed from Flathub by Flatpak itself, with its own notices.

The Montserrat font is embedded in the binaries (converted to C by `tools/export_assets.py`). Under
the SIL Open Font License 1.1 it may be bundled with any software; the font itself may not be sold on
its own, and the license text must accompany it: see [assets/fonts/OFL.txt](assets/fonts/OFL.txt).
The Noto Sans subsets are embedded the same way (`generated/tw_text_data.inc`); they are Modified
Versions under the OFL (only some glyphs kept, static instances, no hinting), made by
`tools/make_font_subsets.py` from the fonts `tools/fetch_fonts.sh` downloads, keep the Noto family
names (none of them is a Reserved Font Name) and come with their license texts in
[assets/fonts/subsets/](assets/fonts/subsets/).

---

## miniz (MIT)

```text
Copyright 2013-2014 RAD Game Tools and Valve Software
Copyright 2010-2014 Rich Geldreich and Tenacious Software LLC

All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## cJSON (MIT)

```text
Copyright (c) 2009-2017 Dave Gamble and cJSON contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## libretro.h (MIT)

```text
libretro.h (https://github.com/libretro/RetroArch) - SPDX-License-Identifier: MIT

The following license statement only applies to this libretro API header (libretro.h).

Copyright (C) 2010-2024 The RetroArch team

Permission is hereby granted, free of charge,
to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## stb_image, stb_truetype (MIT OR Unlicense)

```text
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2017 Sean Barrett
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## SDL3 (Zlib)

```text
Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
```

## dr_mp3 (Unlicense OR MIT-0)

```text
dr_mp3 (https://github.com/mackron/dr_libs) - SPDX-License-Identifier: Unlicense OR MIT-0

This software is available as a choice of the following licenses. Choose
whichever you prefer.

===============================================================================
ALTERNATIVE 1 - Public Domain (www.unlicense.org)
===============================================================================
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>

===============================================================================
ALTERNATIVE 2 - MIT No Attribution
===============================================================================
Copyright 2023 David Reid

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Parts of dr_mp3 are derived from minimp3 (https://github.com/lieff/minimp3):

    To the extent possible under law, the author(s) have dedicated all copyright and related and
    neighboring rights to this software to the public domain worldwide. This software is distributed
    without any warranty. See <http://creativecommons.org/publicdomain/zero/1.0/>.
```
