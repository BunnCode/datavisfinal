/*=========================================================================

  Program:   Visualization Toolkit
  Module:    SpecularSpheres.cxx

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
//
// This examples demonstrates the effect of specular lighting.
//
#include "vtkSmartPointer.h"
#include "vtkSphereSource.h"
#include "vtkPolyDataMapper.h"
#include "vtkActor.h"
#include "vtkInteractorStyle.h"
#include "vtkObjectFactory.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkProperty.h"
#include "vtkCamera.h"
#include "vtkLight.h"
#include "vtkOpenGLPolyDataMapper.h"
#include "vtkJPEGReader.h"
#include "vtkImageData.h"
#include <vtkPNGWriter.h>

#include <vtkPolyData.h>
#include <vtkPointData.h>
#include <vtkPolyDataReader.h>
#include <vtkCleanPolyData.h>
#include <vtkPolyDataNormals.h>
#include <vtkPoints.h>
#include <vtkUnsignedCharArray.h>
#include <vtkFloatArray.h>
#include <vtkDoubleArray.h>
#include <vtkCellArray.h>
#include <vtkDataSetReader.h>
#include <vtkContourFilter.h>
#include <vtkRectilinearGrid.h>
#include <vtkDataSetWriter.h>
#include <vtkRectilinearGridToTetrahedra.h>
#include <vtkUnstructuredGrid.h>

#include <vtkCamera.h>
#include <vtkDataSetMapper.h>
#include <vtkRenderer.h>
#include <vtkActor.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkSmartPointer.h>

#include "LUT.h"
#include <vtkPointLocator.h>
#include <vtkNIFTIImageReader.h>

// ****************************************************************************
//  Function: GetNumberOfPoints
//
//  Arguments:
//     dims: an array of size 3 with the number of points in X, Y, and Z.
//           2D data sets would have Z=1
//
//  Returns:  the number of points in a rectilinear mesh
//
// ****************************************************************************

int GetNumberOfPoints(const int* dims)
{
    // 3D
    return dims[0] * dims[1] * dims[2];
    // 2D
    //return dims[0]*dims[1];
}

// ****************************************************************************
//  Function: GetNumberOfCells
//
//  Arguments:
//
//      dims: an array of size 3 with the number of points in X, Y, and Z.
//            2D data sets would have Z=1
//
//  Returns:  the number of cells in a rectilinear mesh
//
// ****************************************************************************

int GetNumberOfCells(const int* dims)
{
    // 3D
    return (dims[0] - 1) * (dims[1] - 1) * (dims[2] - 1);
    // 2D
    //return (dims[0]-1)*(dims[1]-1);
}


// ****************************************************************************
//  Function: GetPointIndex
//
//  Arguments:
//      idx:  the logical index of a point.
//              0 <= idx[0] < dims[0]
//              1 <= idx[1] < dims[1]
//              2 <= idx[2] < dims[2] (or always 0 if 2D)
//      dims: an array of size 3 with the number of points in X, Y, and Z.
//            2D data sets would have Z=1
//
//  Returns:  the point index
//
// ****************************************************************************

int GetPointIndex(const int* idx, const int* dims)
{
    // 3D
    return idx[2] * dims[0] * dims[1] + idx[1] * dims[0] + idx[0];
    // 2D
    //return idx[1]*dims[0]+idx[0];
}


// ****************************************************************************
//  Function: GetCellIndex
//
//  Arguments:
//      idx:  the logical index of a cell.
//              0 <= idx[0] < dims[0]-1
//              1 <= idx[1] < dims[1]-1 
//              2 <= idx[2] < dims[2]-1 (or always 0 if 2D)
//      dims: an array of size 3 with the number of points in X, Y, and Z.
//            2D data sets would have Z=1
//
//  Returns:  the cell index
//
// ****************************************************************************

int GetCellIndex(const int* idx, const int* dims)
{
    // 3D
    return idx[2] * (dims[0] - 1) * (dims[1] - 1) + idx[1] * (dims[0] - 1) + idx[0];
    // 2D
    //return idx[1]*(dims[0]-1)+idx[0];
}

// ****************************************************************************
//  Function: GetLogicalPointIndex
//
//  Arguments:
//      idx (output):  the logical index of the point.
//              0 <= idx[0] < dims[0]
//              1 <= idx[1] < dims[1] 
//              2 <= idx[2] < dims[2] (or always 0 if 2D)
//      pointId:  a number between 0 and (GetNumberOfPoints(dims)-1).
//      dims: an array of size 3 with the number of points in X, Y, and Z.
//            2D data sets would have Z=1
//
//  Returns:  None (argument idx is output)
//
// ****************************************************************************

void GetLogicalPointIndex(int* idx, int pointId, const int* dims)
{
    // 3D
    idx[0] = pointId % dims[0];
    idx[1] = (pointId / dims[0]) % dims[1];
    idx[2] = pointId / (dims[0] * dims[1]);

    // 2D
    // idx[0] = pointId%dims[0];
    // idx[1] = pointId/dims[0];
}


// ****************************************************************************
//  Function: GetLogicalCellIndex
//
//  Arguments:
//      idx (output):  the logical index of the cell index.
//              0 <= idx[0] < dims[0]-1
//              1 <= idx[1] < dims[1]-1 
//              2 <= idx[2] < dims[2]-1 (or always 0 if 2D)
//      cellId:  a number between 0 and (GetNumberOfCells(dims)-1).
//      dims: an array of size 3 with the number of points in X, Y, and Z.
//            2D data sets would have Z=1
//
//  Returns:  None (argument idx is output)
//
// ****************************************************************************

void GetLogicalCellIndex(int* idx, int cellId, const int* dims)
{
    // 3D
    idx[0] = cellId % (dims[0] - 1);
    idx[1] = (cellId / (dims[0] - 1)) % (dims[1] - 1);
    idx[2] = cellId / ((dims[0] - 1) * (dims[1] - 1));

    // 2D
    //idx[0] = cellId%(dims[0]-1);
    //idx[1] = cellId/(dims[0]-1);
}

#pragma region helpers
///--------------------------------------------------------------------------
/// This should all be moved to proper c++/header files but until such a time
/// it will remain here. This region contains helper functions and structures
/// for vector mathematics 
///--------------------------------------------------------------------------

class vec2;
inline float distance(const vec2 vec1, const vec2 vec2);
class vec3;
inline float distance(const vec3 vec1, const vec3 vec2);

//Saturate the value f between min and max
inline float saturate(float f, float min, float max) {
    return std::min(std::max(f, min), max);
}

//Saturate the value f between 0 and 1
inline float saturate(float f) {
    return saturate(f, 0, 1);
}

///2 dimensional mathematical vector
class vec2 {
public:
    //vector components
    float x;
    float y;

    ///Create a new vec2 with the given params 
    vec2(float x, float y) {
        this->x = x;
        this->y = y;
    }

    vec2(float* pos) {
        this->x = pos[0];
        this->y = pos[1];
    }

    vec2() {
        this->x = 0;
        this->y = 0;
    }

    ///return normalized copy
    vec2 normalized() {
        float x = saturate(this->x);
        float y = saturate(this->y);
        return vec2(x, y);
    }

    //normalize this vector
    void normalize() {
        vec2 norm = this->normalized();
        this->x = norm.x;
        this->y = norm.y;
    }

    ///(0, 0)
    static vec2 zero;

    ///Return the magnitude of this vector
    float magnitude() {
        return distance(vec2::zero, *this);
    }

    //populate the given buffer of size 2 with the x and y positions of this vector
    void to_buffer(float* buf) {
        buf[0] = this->x;
        buf[1] = this->y;
    }

    vec2 operator* (float m)
    {
        return vec2(this->x * m, this->y * m);
    }

    vec2 operator+ (vec2 m)
    {
        return vec2(this->x + m.x, this->y + m.y);
    }

    vec2 operator- (vec2 m)
    {
        return vec2(this->x - m.x, this->y - m.y);
    }

    //Note that this is not true vector "multiplication", it is just memberwise scaling
    vec2 operator* (vec2 m)
    {
        return vec2(this->x * m.x, this->y * m.y);
    }

    //Note that this is not true vector "division", it is just memberwise scaling
    vec2 operator/ (vec2 m)
    {
        return vec2(this->x / m.x, this->y / m.y);
    }


    vec2 operator/ (float m)
    {
        return vec2(this->x / m, this->y / m);
    }

    void operator*= (float m)
    {
        vec2 mult = *this * m;
        this->x = mult.x;
        this->y = mult.y;
    }

    void operator*= (vec2 m)
    {
        vec2 mult = *this * m;
        this->x = mult.x;
        this->y = mult.y;
    }

    void operator-= (vec2 m)
    {
        vec2 sub = *this - m;
        this->x = sub.x;
        this->y = sub.y;
    }

    void operator/= (vec2 m)
    {
        vec2 div = *this / m;
        this->x = div.x;
        this->y = div.y;
    }

    void operator+= (const vec2 m)
    {
        vec2 add = *this + m;
        this->x = add.x;
        this->y = add.y;
    }

    friend auto operator<<(std::ostream& os, vec2 const& vec) -> std::ostream& {
        return os << "(" << vec.x << "," << vec.y << ")";
    }
};
vec2 vec2::zero = vec2(0, 0);

//3 dimensional mathematical vector
class vec3 {
public:
    //members
    float x;
    float y;
    float z;

    ///Create a new vec3 with the given params 
    vec3(float x, float y, float z) {
        this->x = x;
        this->y = y;
        this->z = z;
    }

    vec3() {
        this->x = 0;
        this->y = 0;
        this->z = 0;
    }

    ///return normalized copy
    vec3 normalized() {
        float x = saturate(this->x);
        float y = saturate(this->y);
        float z = saturate(this->z);
        return vec3(x, y, z);
    }

    //normalize this vector
    void normalize() {
        vec3 norm = this->normalized();
        this->x = norm.x;
        this->y = norm.y;
        this->z = norm.z;
    }

    //(0, 0, 0)
    static vec3 zero;

    ///returns the magnitude of this vector
    float magnitude() {
        return distance(vec3::zero, *this);
    }

    vec3 operator* (float m)
    {
        return vec3(this->x * m, this->y * m, this->z * m);
    }

    vec3 operator/ (float m)
    {
        return vec3(this->x / m, this->y / m, this->z / m);
    }

    vec3 operator/ (vec3 m)
    {
        return vec3(this->x / m.x, this->y / m.y, this->z / m.z);
    }

    vec3 operator* (vec3 m)
    {
        return vec3(this->x * m.x, this->y * m.y, this->z * m.z);
    }

    void operator*= (float m)
    {
        vec3 mult = *this * m;
        this->x = mult.x;
        this->y = mult.y;
        this->z = mult.z;
    }


    void operator*= (vec3 m)
    {
        vec3 mult = *this * m;
        this->x = mult.x;
        this->y = mult.y;
        this->z = mult.z;
    }

    void operator/= (vec3 m)
    {
        vec3 div = *this / m;
        this->x = div.x;
        this->y = div.y;
        this->z = div.z;
    }

    vec3 operator+ (const vec3 m)
    {
        return vec3(this->x + m.x, this->y + m.y, this->z + m.z);
    }

    void operator+= (const vec3 m)
    {
        vec3 add = *this + m;
        this->x = add.x;
        this->y = add.y;
        this->z = add.z;
    }

    vec3 operator- (const vec3 m)
    {
        return vec3(this->x - m.x, this->y - m.y, this->z - m.z);
    }

    void operator-= (const vec3 m)
    {
        vec3 min = *this - m;
        this->x = min.x;
        this->y = min.y;
        this->z = min.z;
    }

    ///Convert this vec3 into a pixel and populate returned with its value
    void to_pixel(unsigned char* returned) {
        returned[0] = unsigned char(x * 255);
        returned[1] = unsigned char(y * 255);
        returned[2] = unsigned char(z * 255);
    }

    friend auto operator<<(std::ostream& os, vec3 const& vec) -> std::ostream& {
        return os << "(" << vec.x << "," << vec.y << "," << vec.z << ")";
    }
};
vec3 vec3::zero = vec3(0, 0, 0);

///Given a range between min and max, return the ratio of val between them
inline float scalar(float min, float max, float val) {
    float dist = val - min;
    float range = max - min;
    return(dist / range);
}

///Lerp between two floats given a float t 
inline float lerp(const float x1, const float x2, const float t) {
    return x1 + (t * (x2 - x1));
}

///Lerp between two vec2s given a float t
inline vec2 lerp(const vec2 v1, const vec2 v2, const float t) {
    return vec2(
        lerp(v1.x, v2.x, t),
        lerp(v1.y, v2.y, t)
    );
}

///Lerp between two vec3s given a float t
inline vec3 lerp(const vec3 v1, const vec3 v2, const float t) {
    return vec3(
        lerp(v1.x, v2.x, t),
        lerp(v1.y, v2.y, t),
        lerp(v1.z, v2.z, t)
    );
}

///calculate distance between two vec2s
inline float distance(const vec2 vec1, const vec2 vec2) {
    float x = pow((vec1.x - vec2.x), 2);
    float y = pow((vec1.y - vec2.y), 2);
    return sqrt(x + y);
}

///calculate distance between two vec3s
inline float distance(const vec3 vec1, const vec3 vec2) {
    float x = pow((vec1.x - vec2.x), 2);
    float y = pow((vec1.y - vec2.y), 2);
    float z = pow((vec1.z - vec2.z), 2);
    return sqrt(x + y + z);
}

#pragma endregion helpers

//from https://stackoverflow.com/questions/7367770/how-to-flatten-or-index-3d-array-in-1d-array
int to1DIndex(int x, int y, int z, int xMax, int yMax) {
    return (z * xMax * yMax) + (y * xMax) + x;
}

vec3 to3DIndex(int idx, int xMax, int yMax) {
    int z = idx / (xMax * yMax);
    idx -= (z * xMax * yMax);
    int y = idx / xMax;
    int x = idx % xMax;
    return vec3(x, y, z);
}

int main()
{
    //Prompt for filename
    std::cout << "Input filename: ";
    std::string inputFilename;
    std::getline(std::cin, inputFilename);

    //initialize NFTI reader
    vtkNIFTIImageReader* nftireader = vtkNIFTIImageReader::New();
    nftireader->SetFileName(inputFilename.c_str());
    nftireader->Update();

    //Load file
    if (nftireader->GetOutput() == NULL || nftireader->GetOutput()->GetNumberOfCells() == 0)
    {
        cerr << "Could not find input file." << endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "MRI file " << inputFilename << " loaded." << std::endl;

    //Get properties from file
    vtkImageData* imagedata = (vtkImageData*)nftireader->GetOutput();
    int dims[3];
    imagedata->GetDimensions(dims);
    double boundData[6];
    imagedata->GetBounds(boundData);

    //origin and bounds for normalization of data
    vec3 origin = vec3(boundData[0], boundData[2], boundData[4]);
    vec3 bounds = vec3(
        abs(boundData[0] - boundData[1]),
        abs(boundData[2] - boundData[3]),
        abs(boundData[4] - boundData[5]));
    std::cout << "Properties loaded." << std::endl;

    //Sampler for data
    vtkSmartPointer<vtkPointLocator> locator = vtkPointLocator::New();
    locator->SetDataSet(imagedata);
    locator->BuildLocator();

    //auto test = rgrid->GetPoint(0, { 0.5f, 0.5f, 0.5f });
    int ncells = imagedata->GetNumberOfCells();
    cerr << "Number of cells to convert is " << ncells << endl;

    fstream ofs;

    //Write output
    std::cout << "Output filename (program looks for \"rawdata.bytes\" by default): ";
    std::string outputFilename;
    std::getline(std::cin, outputFilename);
    ofs.open(outputFilename, ios::out | ios::trunc | std::ios::binary);
    
    //Resolution of output file
    std::cout << "Output resolution: ";
    std::string resolutionStr;
    std::getline(std::cin, resolutionStr);
    const int ResX = stoi(resolutionStr);
    const int ResY = stoi(resolutionStr);
    const int ResZ = stoi(resolutionStr);
    const int SliceRes = ResX * ResY;

    ///write resolution information
    ofs.write(reinterpret_cast<const char*>(&ResX), sizeof(ResX));
    ofs.write(reinterpret_cast<const char*>(&ResY), sizeof(ResY));
    ofs.write(reinterpret_cast<const char*>(&ResZ), sizeof(ResZ));
    
    //write aspect ratio information
    vec3 aspectratio = bounds / bounds.x;
    ofs.write(reinterpret_cast<const char*>(&aspectratio.x), sizeof(float));
    ofs.write(reinterpret_cast<const char*>(&aspectratio.y), sizeof(float));
    ofs.write(reinterpret_cast<const char*>(&aspectratio.z), sizeof(float));

    //here we go
    int i = 0;
    float max = -10000;
    float min = 10000;

    float *values = (float*)malloc(sizeof(float) * (ResX * ResY * ResZ));

    for (i = 0; i < ResX * ResY * ResZ; i++) {
        //Sample data
        vec3 logindex = to3DIndex(i, ResX, ResY);
        vec3 normpos = logindex / vec3(ResX, ResY, ResZ);
        vec3 scaledpos = normpos * bounds;
        scaledpos += origin;
        
        double pt[] = { scaledpos.x, scaledpos.y, scaledpos.z };
        
        vtkIdType id = locator->FindClosestPoint(pt);
        double pnt_found[1];

        imagedata->GetPointData()->GetScalars()->GetTuple(id, pnt_found);

        float data = (float)pnt_found[0];
        if (max < data)
            max = data;
        if (min > data)
            min = data;

        values[i] = data;
        if (i % (SliceRes) == 0)
            std::cout << "Processed Slice " << logindex.z << " Of " << ResZ << std::endl;
    }

    //Write data to file
    for (int u = 0; u < i; u++) {
        vec3 logindex = to3DIndex(u, ResX, ResY);
        float writtenval = (values[u] - min) / abs(max - min);
        ofs.write(reinterpret_cast<const char*>(&writtenval), sizeof(float));
    }
    free(values);
    //Close the file
    ofs.close();

    std::cout << "Output file " << outputFilename << " written." << std::endl;
    return 1;//Success
}
