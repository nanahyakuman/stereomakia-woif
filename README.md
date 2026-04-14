# STEREOMAKIA;; War on Infinite Fronts
is an arcade rhythm game for your home controller. It's inspired most directly by ongeki but plays more like sdvx in reality.[^a]
[^a]: It's built on top of the original [STEREOMAKIA](https://nanahyakuman.itch.io/stereomakia) no one played, hence the herculean inital commit.

WoIF is intended to be free on release, although I will probably set up donations somehow or other.

## To-Do

Right now I'm working on improving the editor experience so that someone other than myself could realistically use it after a video or two of primer, and greater overall track capabilities alongside (soflan, color customization, soundodger-style bgs & shaders w/ automations, &c.). WoIF is basically to be the Soundodger+ to STEREOMAKIA's Soundodger.[^e]
[^e]: Soundodger is awesome.

I'm also planning for steam workshop support—I don't really want to run my own forums and I wouldn't be the first steam rhythm game to generously define "fair use". I do still want a new launch tracklist that's a little more defensible than the original's though.

I will probably be working pretty slow but for the time being I don't intend on taking external PRs. No one else deserves to go through this code anyways ;p.

## Dev Info
WoIF depends on the [Project Heartbeat Engine](https://github.com/EIRTeam/Project-Heartbeat-Engine), NOT regular Godot.[^d] Some level-editor functionality also depends on `/ffmpeg/bin/ffmpeg.exe` existing (and like, being the real ffmpeg executable), although it's optional right now.
[^d]: You should really check out Project Heartbeat & I'm not just saying that bc I'm using their engine, athough I hope it's clear I'm grateful for their public contributions.

Levels will not work without their `.ogg` files present. Also, `.ogg` files are in the .gitignore. This is really annoying and may not be true long-term but at least when I was working on original STEREOMAKIA they were really slow to upload, so orz in advance.[^f]
[^f]: If one were to soundcloud downloader the indicated songs that'd be super mega instadeath illegal but they would also sync up perfectly nudge nudge nudge

All code is presently all-rights-reserved but will probably transition into some sort of MIT or CC-BY long-term. But to be clear, levels you create with the in-game editor obviously belong to you, insofaras a set of text files is meaningfully ownable.
