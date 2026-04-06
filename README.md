# STEREOMAKIA;; War on Infinte Fronts
is an arcade rhythm game for your home controller. It's inspired most directly by ongeki but plays more like sdvx in reality.[^a]
[^a]: It's built on top of the original [STEREOMAKIA](https://nanahyakuman.itch.io/stereomakia) no one played, hence the herculean inital commit.

Right now I'm working on improving the editor experience so that someone other than myself could realistically use it after a video or two of primer. I also plan for greater overall track capabilities (think soflan, color customization, soundodger-style shader automations, &c.). WoIF is basically to be the Soundodger+ to STEREOMAKIA's Soundodger.[^e]
[^e]: Soundodger is awesome.

I also need to make a new set of levels that aren't copyright nuclear bombs.[^b]
[^b]: The original is really grounded in hyperflip/daria/plunderphonic/&c. type music but unfortunately "copyright is cringe and technofascist" doesn't hold up in court.

## Dev Info
WoIF depends on the [Project Heartbeat Engine](https://github.com/EIRTeam/Project-Heartbeat-Engine), NOT regular Godot.[^d] Some level-editor functionality also depends on `../ffmpeg/bin/ffmpeg.exe` existing (and like, being the real ffmpeg executable), although it's optional right now. (The actual root for the project is really one folder above this one, this is just the godot repo).
[^d]: You should really check out Project Heartbeat & I'm not just saying that bc I'm using their engine, athough I hope it's clear I'm grateful for their public contributions.

Levels will not work without their `.ogg` files present. Also, `.ogg` files are in the .gitignore. This is really annoying and may not be true long-term but at least when I was working on original STEREOMAKIA they were really slow to upload, so orz in advance.

All code is presently all-rights-reserved but will probably transition into some sort of CC-BY long-term, although that's no legal guarantee. Like with [Violet Impetus](https://github.com/nanahyakuman/violet-impetus-gm), I open-source the code for the curious and the unwilling-to-pay but make no guarantees about quality or readability. Although to be clear, levels you create with the in-game editor obviously belong to you.[^c]
[^c]: insofaras a set of `.json` files is meaningfully ownable.
