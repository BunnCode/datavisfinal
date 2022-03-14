# README #

# Media from presentation #
https://www.youtube.com/watch?v=rANeiJdTxy0
https://www.youtube.com/watch?v=cQdGWc5PIlc

# Prepping data #
Data prep is done via the VtkConverter sub-project. It is a VTK project written in C++, and is in the directory VtkConverter/. It should build via cmake with no problems.

The converter takes in .NII (NIfTI) MRI files. The ones used in the demos are located here: http://www.informatik.uni-leipzig.de/~wiebel/public_data/index.html

To convert the files into the intermediary format used by the Unity project, simply run the built program and it will prompt you to take the necessary steps. Recommended output resolution is beween 100-300. Make sure that the file is named "rawdata.bytes" and is placed into any of the Unity project's Resources directories so that it is properly loaded in the editor.

The processed binary file contains resolution and scaling information. For more details, look at VtkConverter/VTKConverter.cxx and read the comments. The program itself is fairly straightforward, other than helper functions. 

# Visualizing data #
The Unity project itself is the visualizer. To open the project in Unity, simply load the root directory in the unity browser. 

Visualization is done by processing the intermediary binary file format, converting it into a 3d texture, and then bumping that texture to the GPU. By doing so, framerate is not capped by CPU callback speed and can remain quite high. 

The CPU logic is contained within the Assets/DensityRend/Scripts/DensityRend.cs file. See the file itself for specifics on mechanisms, but the broad strokes are that it converts screenspace points into worldspace vectors that can then be interpolated between for casting rays for individual fragments in the shader file; this is done for each eye based on its projection matrix and other parameters. It also generates the 3d texture used by the shader for rendering. 

The GPU logic is contained within the Assets/DensityRend/Resources/DensityRenderer.shader file. This shader reads data from the 3d texture for the purpose of ray marching rendering. A few tricks were used to eek out as many frames as possible.

First, rays are immediately stepped up to the point of the rendering volume using an AABB intersection position test.
![image](https://user-images.githubusercontent.com/17638042/158109504-50e326fd-6d76-4018-b9fe-54c305529720.png)
This test is also used for a second purpose; the "close" point is where the ray starts marching, and the "far" point is where it stops marching. In doing so, not a single step is wasted and images will appear very high resolution at even much lower numbers of steps. 
Additionally, fragments are immediately clipped if they fail this intersection test. The shader was designed with no branching whatsoever, and the 3d texture is in a 1d float format which also saves time on sampling.

For builds, ensure that the rawdata.bytes file is in the data directory or it will not load.
