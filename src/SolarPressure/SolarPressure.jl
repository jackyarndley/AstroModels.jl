module SolarPressure

using StaticArrays

using JSMDInterfaces.Models: AbstractJSMDModelData, AbstractJSMDModel
import JSMDInterfaces.Models: parse_data, parse_model
using JSMDUtils.Math: unitvec

include("abstract.jl")
include("pressure.jl")
include("cannonball.jl")
include("flatplate.jl")

end