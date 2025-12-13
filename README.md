Garage Robbery - FiveM Script (with ox_target)
Description:

This script adds a garage robbery feature to your FiveM server using ox_target. Players can interact with garages and receive random items after successfully robbing them. It's fully customizable and easy to configure.

Required Dependencies:

scully-emotes or other emote libraries

ox_inventory (for inventory)

ox_lib (for various functions)

dispatch (for triggering robbery events)

ox_target (for interaction)

Features:

Garage Robbery via ox_target: Rob garages by interacting with them using ox_target.

Item Rewards: After a successful robbery, players receive random items (e.g., money, weapons, drugs).

Custom Cooldown: Set cooldowns to limit how often players can rob the same garage.

Easy Configuration: Customize cooldowns, item rewards, and other settings in config.lua.

Emote Support: Add animations for a realistic experience if scully-emotes or other emotes are installed.

Automatic Notifications: Notify players when a garage is being robbed.

Protection: Prevent robbery attempts when police or other players are nearby.

How It Works:

Interact with the Garage: Players use ox_target to interact with a garage. Once triggered, the robbery begins.

Receive Items: After a successful robbery, players receive random items added to their inventory.

Cooldown: A cooldown is applied to prevent multiple robberies in a short time frame.

Emote Animations: Add emote animations for a more immersive experience when robbing garages.

Installation:

Download the script and place it in your server directory.

Ensure required dependencies (ox_inventory, ox_lib, dispatch, ox_target) are installed.

Configure the script in config.lua.

Restart your server and test the feature.

Changelog:

Version 1.0: Initial release with garage robbery, item rewards, and cooldowns.

Planned Features: More item types, animation support, and notifications.
