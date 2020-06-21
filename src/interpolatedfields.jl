# routines for creating interpolatable forms of grid data


export interpolated_history


"""
    interpolated_history(v::History,tr)

Returns a function that interpolates the history `v`, using the time specified
by time range `tr`. Uses cubic spline interpolation. If `v` is a periodic history,
then the resulting function is also periodic.
"""
function interpolated_history(v::History{T,PeriodicHistory},tr::AbstractRange) where {T}
  length(tr) == length(v)+1 || error("Incommensurate lengths of history and range")
  return CubicSplineInterpolation(tr,Base.unsafe_view(v,1:length(tr)),extrapolation_bc=Periodic())
end

function interpolated_history(v::History{T,RegularHistory},tr::AbstractRange) where {T}
  length(tr) == length(v) || error("Incommensurate lengths of history and range")
  return CubicSplineInterpolation(tr,v,extrapolation_bc=Periodic())
end

"""
    interpolated_history(v::History,xr,yr,tr)

Returns a function that interpolates the history `v` both spatially and temporally,
using the x and y ranges specified by `xr` and `yr` and time specified by time range
`tr`. Uses cubic spline interpolation in all directions. If `v` is a periodic history,
then the resulting function is also periodic in time.
"""
function interpolated_history(v::History{T,PeriodicHistory},xr::AbstractRange,yr::AbstractRange,tr::AbstractRange) where {T}
  # v is a PeriodicHistory, so need to add first element to last here
  nx, ny = size(v[1])
  vhist = zeros(nx,ny,length(v)+1)
  for i in 1:size(vhist,3)
    vhist[:,:,i] = v[i]
  end
  (length(xr) == nx && length(yr) == ny && length(tr) == length(v)+1) || error("Incommensurate lengths of history and range")

  return CubicSplineInterpolation((xr, yr ,tr), vhist, extrapolation_bc = (Flat(),Flat(),Periodic()))

end
