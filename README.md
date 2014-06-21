NODE KITTEN

provides similar high level openGL pipeline control to Apple’s Scene Kit.

currently migrating to GL330 core on desktop and iOS

lot’s to do, this should be considered under construction.

see to ToDoList.txt in NKCore folder

DEPENDENCIES / 3rd PARTY LICENSES / SHOUT OUTS

MIKMidi - source included - Original author: Andrew R. Madsen (andrew@mixedinkey.com) https://github.com/mixedinkey-opensource/MIKMIDI
ASSIMP - source included - https://github.com/assimp/assimp
Bullet 3d - source included - https://github.com/bulletphysics/bullet3

Some math functions from apple’s GL KIT
Some math functions from GFX (sio2)
Some math functions from OPEN FRAMEWORKS

TO USE:

Confirm demo app works on your platform

1. add NKCore folder to your project
2. put an NKView or NKUIView in an XIB file, 
3. make a subclass NKSceneNode as ‘MyScene’ etc. 
4. in app delegate or elsewhere, set your view’s scene property to ‘MyScene’.

- modules specific istructions -

to ignore modules, remove folder 'group' from xcode project, flag #NK_USE_xxx to 0 in NKMacro.h

*MIKMidi for iOS target requires libxml2 added target link binary with libraries, also add to header search paths: $(SDKROOT)/usr/include/libxml2

IN USE:

Most of the API flow resembles Apple’s SpriteKit / Scene Kit with a few variations. Most animation / event handling done with ^blocks.