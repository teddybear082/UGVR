# UGVR
 A mod to transform Godot 4 games from 3D to VR

## IN DEVELOPMENT.

## Presently working:

-Inject VR camera into most Godot 4 3D games tested in the position of the active camera

-Display 2D UI of most Godot 4 3D games in an interactable panel in the VR world

-Basic emulation of xbox game pad with motion controls (hotkey to enable start,select and dpad)

-Turn on/off menu pointers with gesture (place hand near top of head and press trigger)

-Take user height into account for camera position with gesture (place right hand near top of head and press B/Y)

-reload user config of action map on demand in case game overwrites it, with gesture (place left hand near top of head and press B/Y)


-Snap and smooth turn of user camera (right now, default set to snap since no user config yet)

-Allow user to map input action map actions to VR Controls (in the alternative of default mapping, for example, for pure keyboard games) (currently via manual config file only, which is created automatically when running game with mod for the first time in a special XRConfigs folder)  - see https://github.com/teddybear082/UGVR/wiki/Remapping-Controls-with-Action-Map-Config for more details.

## Presently not working / Roadmap:

-Implement options menu GUI

-Allow user to save game options config

-Allow user to remap controls in interface 


-Allow user to change the location of the viewports where game 2D elements / Canvas layer appear


-Allow user to modify game (like UEVR) to change camera transform, reparent XR camera to a different game element, child nodes to controller locations

## Use

Not presently intended for regular users as this tool is in heavy development / testing, and the code may regularly break or change. For devs or testers, see instructions in Wiki: https://github.com/teddybear082/UGVR/wiki/Getting-Started

# CREDITS

-Decacis for inventing a way to easily inject XR Origin into camera for Godot 4 3D games

-JulianTodd and Decacis for figuring out a way for 2D UI in 3D games to work "universally" in VR with input, and Bastiaan Olij for a fix to get CanvasLayer elements to appear in VR

-Godot XR Tools team - going to be heavily leveraging scripts from Godot XR Tools

-Praydog for concept of universal VR mod (for Unreal Engine) and providing advice about potential methods to display 2D UI in VR
