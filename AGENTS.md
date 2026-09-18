# Project

This is a Godot 4 tower defense game for a game jam themed
"Pass It On."

## Core mechanic

Towers cannot attack by themselves.

The player gives towers pre-packaged attacks. A tower can use
an attack package and pass it to another tower.

The central gameplay should revolve around deciding when and
where attacks should be passed.

## Development guidelines

- Use Godot 4.
- Use GDScript.
- Keep the architecture simple and appropriate for a game jam.
- Prefer small reusable scenes.
- Do not over-engineer systems.
- Keep scripts organized under scripts/.
- Keep scenes organized under scenes/.
- Use .tres resources for attack definitions when appropriate.
- Explain major architectural changes before making them.
- Do not add large systems unless they are necessary for the current gameplay milestone.