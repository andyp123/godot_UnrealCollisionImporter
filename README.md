# Unreal Collision Importer
An import script that imports manually created collision data set up for Unreal into [Godot](godotengine.org/) game engine.

If you have libraries of objects with carefully set up collision from Unreal projects or asset packs and want to get that collision into Godot, you can use this tool to do so. It detects the prefixes used by Unreal to import manually created collisions and allows Godot to use them too.

## Supports:
- Multiple colliders per object (under a single StaticBody)
- Box, Sphere, Capsule and Convex colliders
- Colliders can be translated and rotated relative to the main object

## Usage:
- Put the script 'UE4CollisionImporter.gd' anywhere in your project folder.
- Select the import settings for any file containing correctly set up meshes and set the "Custom Script" parameter by selecting the script.
- Press the reimport button and the colliders set up in your file should be translated into Godot.
NOTE: This script has yet to be exhaustively tested. There may be bugs, so if you find them, sorry for the inconvenience and please report them.

The meshes in your scene should be named with the correct prefixes relative to the object they will be attached to and in a flat hierarchy. For example:
Table
UCX_Table_1
UBX_Table_1
UBX_Table_2
UBX_Table_3
UBX_Table_4
'Table' is the model that will be visible in game, 'UCX_Table_1' is a convex collider that could allow the top to be cylindrical, hexagonal etc. and 'UBP_Table_1-4' could be the table legs. The benefit of setting up your meshes this way over using automatic convex decomposition tools in Godot is that you can explicitly define the exact collision as well as make use of the primitive shape colliders such as box and sphere that should be more efficient than convex colliders.

For more information on Unreal's static mesh collision workflow, please check the [official documentation](https://docs.unrealengine.com/4.26/en-US/WorkingWithContent/Importing/FBX/StaticMeshes/#collision).
