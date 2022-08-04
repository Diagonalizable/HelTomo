# HelTomo
HelTomo - Helsinki Tomography Toolbox

HelTomo is a MATLAB toolbox that has been primarily created for working with X-ray Computed Tomography (CT) data measured in the Industrial Mathematics Computed Tomography Laboratory at the University of Helsinki. Its purpose is facilitate a fast and easy workflow from raw projection data to reconstructions, allowing scientists to test their CT algorithms on real, measured X-ray data.

Full use of the toolbox requires that the ASTRA Tomography Toolbox (https://www.astra-toolbox.com/) and the Spot Linear-Operator Toolbox (https://www.cs.ubc.ca/labs/scl/spot/) have been added to the MATLAB path. Many functions also require that the computer is also equipped with a CUDA-enabled GPU. Computing CT reconstructions is a heavy task, and use a GPU-based workstation is strongly recommended.

The HelTomo toolbox has been created by Alexander Meaney while working at the Department of Mathematics and Statistics at the University of Helsinki.
