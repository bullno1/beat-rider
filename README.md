# beat-rider

[![Build status](https://github.com/bullno1/beat-rider/actions/workflows/build.yml/badge.svg)](https://github.com/bullno1/beat-rider/actions/workflows/build.yml)

An old prototype of a [Audiosurf](https://store.steampowered.com/app/12900/AudioSurf/) clone, uploaded for archival and sharing purpose.

Powered by:

* [Moai](https://github.com/moai/moai-dev): Cross platform game engine
* [aubio](https://aubio.org/): Audio analysis library.
  Take note: Unlike this project, it's licensed under [GPLv3](https://github.com/aubio/aubio/blob/master/COPYING).

# Building

For the list of dependencies, refer to the [CI workflow](.github/workflows/build.yml).

```
./bootstrap
./run
```

This project was originally built for mobile devices but the toolchains have changed a lot over the years and I do not have the time to make it build.

# Project layout

* assets
* deps
  * moai: Moai, bundled as a submodule to simplify distribution
  * easter: Custom build helpers, bundled as a submodule to simplify distribution
* hosts
  * android: Android host, not guaranteed to work
  * titan: Desktop host built and tested in CI
* plugins
  * moai-aubio: Aubio plugin for Moai
* profiles: Different mobile device profiles
* src: Main source of the game
  * glider: Framework on top of Moai
  * main.lua: Entrypoint

## Audio analysis

The bulk of the analysis can be found in [`src/Analysis.lua`](src/Analysis.lua).
Caching of analyzed tracks has been disabled since the old openssl (used for hashing) no longer builds on modern platforms.

A graph is constructed to send raw audio into various analyzer node powered by aubio.
The extracted features are also normalized, smoothed and thresholded to generate level features.

While this file defines the pipeline, concrete parameters can be found in [`src/DeveloperOptions.lua`](src/DeveloperOptions.lua).
The values are obtained using pure vibes and I suspect there are better ways such as using a sliding window instead of a global threshold.
The pipeline itself is also defined using a combination of vibes and reading some interview articles of the original developer of Audiosurf (which I can no longer find the links to).

## Using your own song

1. Put an *mp3* file in `assets/sfx`
2. Update `main.lua` to point to the new file

The default song is [Bad Apple](https://www.youtube.com/watch?v=9lNZ_Rnr7Jc) but there's a long stretch of no onset detected and I have no idea why.

Some songs that seem to work well (not included due to copyright):

* Radioactive: https://www.youtube.com/watch?v=ktvTqknDobU
* E La Don Che: https://www.youtube.com/watch?v=K01LvulhFRg
* Oh NaNa: https://www.youtube.com/watch?v=yPTcKSVAEvA
