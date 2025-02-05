# UGVR
 A mod to transform Godot 4 games from 3D to VR

## IN DEVELOPMENT.
![thumb](https://github.com/teddybear082/UGVR/assets/87204721/2a7b55f6-605f-47ab-9964-d838c543f3a6)

https://vimeo.com/924331826

## Presently working:

-Inject VR camera into most Godot 4 3D games tested in the position of the active camera and display "VR Hands"

-Display 2D UI of most Godot 4 3D games in an interactable panel in the VR world

-Basic emulation of xbox game pad with motion controls (hotkey to enable start,select and dpad)

-Turn on/off menu pointers with gesture (place hand near top of head and press trigger)

-Take user height into account for camera position with gesture (place right hand near top of head and press B/Y)

-reload user config of action map on demand in case game overwrites it, with gesture (place left hand near top of head and press B/Y)

-Snap and smooth turn of user camera (right now, default set to snap since no user config yet)

-Allow user to change between HMD-directed and controller-directed movement

-Allow user to map input action map actions to VR Controls (in the alternative of default mapping, for example, for pure keyboard games) (currently via manual config file only, which is created automatically when running game with mod for the first time in a special XRConfigs folder)  - see https://github.com/teddybear082/UGVR/wiki/Remapping-Controls-with-Action-Map-Config for more details.

-Allow user to convert to roomscale mode, intended for FPS games, to reparent the XR elements to the player CharacterBody3D, and walk around in room and turn freely while having in game character reflect those movements (may have unintended effects in third person mode, not tested)

-Allow user to change the location of the viewports where game 2D elements / Canvas layer appear

-Allow user to change the resolution of the viewports where game 2D elements / Canvas layer appear

-Allow user to make changes to VR game options config so they are loaded and retained between game sessions

-Allow user to use custom hand radial menu with either emulated buttons or emulated game actions 

-Allow user to implement custom code to reparent game object to primary controller and adjust game position relative to hand

-Allow user to print to log current scene tree (scene_tree_pretty) for use in developing game-specific code

-Basic in-VR GUI for simple VR options (still testing)

## Presently not working / Roadmap:

-Allow user to modify game (like UEVR) to change camera transform, reparent XR camera to a different game element

## Use

Not presently intended for regular users as this tool is in heavy development / testing, and the code may regularly break or change. For devs or testers, see instructions in Wiki: https://github.com/teddybear082/UGVR/wiki/1.-Getting-Started

# CREDITS

-Decacis for inventing a way to easily inject XR Origin into camera for Godot 4 3D games.  Check out Decacis's game BadaBoom on Oculus AppLab: https://meta.com/experiences/5816419461787331/

-JulianTodd and Decacis for figuring out a way for 2D UI in 3D games to work "universally" in VR with input, and Bastiaan Olij for a fix to get CanvasLayer elements to appear in VR as well as code for example of CharacterBody3D driven XR origin.  Check out JulianTodd's game TunnelVR on Sidequest: https://sidequestvr.com/app/1630/tunnelvr

-Lejar for radial menu code again: https://github.com/lejar 

-Godot XR Tools team - going to be heavily leveraging scripts from Godot XR Tools: https://github.com/GodotVR/godot-xr-tools

 -Check out MalcolmNixon's Youtube here: https://www.youtube.com/@MalcolmANixon

 -Check out Bastiaan Olij's Youtube here: https://www.youtube.com/c/BastiaanOlij

 -Check out DigitalNightmare's Steam Page here: https://store.steampowered.com/developer/DNeU and Youtube here: https://www.youtube.com/@DigitalN8m4r3

-Avat / patrykkalinowski for the node smoothing code found in his MIT licensed github repo here: https://github.com/patrykkalinowski/godot-xr-kit/tree/master/addons/xr-kit/smooth-input-filter

-Brane from BRANEGAMES for help with godot 2d UI for the UGVR UI. Check out his games on steam here: https://store.steampowered.com/publisher/brane

-Praydog for concept of universal VR mod (for Unreal Engine - UEVR) and providing advice about potential methods to display 2D UI in VR
