# GridUtilities.jl

_Utility functions for discrete fields defined on grids_

| Build Status |
|:---:|
| [![Build Status](https://github.com/JuliaIBPM/GridUtilities.jl/workflows/CI/badge.svg)](https://github.com/JuliaIBPM/GridUtilities.jl/actions) [![Coverage](https://codecov.io/gh/JuliaIBPM/GridUtilities.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaIBPM/GridUtilities.jl) |

## About the package

This package provides various utility functions for working with fields defined on Cartesian grids or on points immersed in these grids. This includes functions for
* Storing histories of these fields
* Creating interpolatable versions of the fields that can be interrogated in function-like manner
* Storing data, writing to file, and loading from file

This is a registered package in Julia, so it can be installed in the usual way,

```julia
] add GridUtilities
```
Then type
```julia
using GridUtilities
```

### Data sampling

Here, we will sample and store data from a simple update model

```julia
u0 = ones(5,5)
t = 0.0
u = deepcopy(u0)
```
Now we set up a `StorePlan` to provide details on what we wish to store and how often. We assign names to each variable.

```julia
t_sample = 0.05
S = StorePlan(t_sample,"state" => u0, "time" => t)
data_history = initialize_storage(S)
```
When we advance a simple dynamical model, we store the data at the sampling interval with `store_data!`

```julia
store_data!(data_history,t,S,"state"=>deepcopy(u),"time"=>t) # initial state
for i in 1:100
    u .+= u0 # simple model, just for making it dynamic
    t += 0.01
    store_data!(data_history,t,S,"state"=>u,"time"=>t)
end
```

The data is stored in a Dict structure that is easy to inspect:
```julia
data_history["state"][3]
data_history["time"][3]
```

The package uses [JLD](https://github.com/JuliaIO/JLD.jl) to save and load data. To save the full set of stored data, e.g.,
```julia
save("stuff.jld","data",data_history)
```
and to load it back in
```julia
d = load("stuff.jld")
```
and, e.g., type
```julia
d["data"]["state"]
```
to get the history of the `state` variable.

### Writing data to file

The package also has capabilities for writing data periodically to file (i.e., writing a *restart* file). Let's see how this would work

```julia
u0 = ones(5,5)
t = 0.0
u = deepcopy(u0)
```

We set up a `WritePlan` for this periodic storage. Here, we specify writing the data every 0.1 time increments.
```julia
filen = "restart.jld"
restart_Δt = 0.1
R = WritePlan(filen,restart_Δt,"state" => u,"t" => t)
```

Now, in the loop, we use an extended version of the `JLD.save` function.
```julia
for i in 1:100
    u .+= u0 # simple model, just for making it dynamic
    t += 0.01
    save(t,R,"state" => u,"t" => t)
end
```

We can restart this by loading from the file
```julia
restart = load(R)
u = restart["state"]
t = restart["t"]
```
and keep running
```julia
for i in 1:100
    u .+= u0 # simple model, just for making it dynamic
    t += 0.01
    save(t,R,"state" => u,"t" => t)
end
```
