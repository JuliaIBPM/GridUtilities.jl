@reexport using JLD
import JLD: save, load

export WritePlan,StorePlan, initialize_storage, store_data!


"""
    WritePlan(file,write_Δt,varlist)

Create a plan for writing data to file. The filename `file` is specified,
to be written to every `write_Δt` time units. The variable names to be written are
specified as a set of dictionary pairs in `varlist`.
"""
struct WritePlan
    filen::String
    write_Δt::Float64
    vardict::Dict
    WritePlan(filen,write_Δt,varlist...) = new(filen,write_Δt,_get_typedict(varlist))
end

"""
    save(t,R::WritePlan,v)

Check if time `t` is appropriate for writing to file, according to the WritePlan `R`,
and if so, write the specified variables `v` (which may be separated by commas)
in `R` to the file in `R`.
"""
function save(t,R::WritePlan,v...)
    tol = 1e-8
    if (isapprox(mod(t,R.write_Δt),0,atol=tol) ||
        isapprox(mod(t,R.write_Δt),R.write_Δt,atol=tol))
        save(R.filen,_writelist(R,v...)...)
    end
end

"""
    load(R::WritePlan[,var::String])

Load the data stored in the file specified by the WritePlan `R`. If
variable `var` is specified, outputs the specified variable.
"""
load(R::WritePlan) = load(R.filen)
load(R::WritePlan,v...) = load(R.filen,v...)

function _writelist(R::WritePlan,varlist...)
    @assert length(R.vardict)==length(varlist)
    list = ()
    for v in varlist
        @assert haskey(R.vardict,v.first) "No such variable exists in this list"
        @assert typeof(v.second) == R.vardict[v.first] "Invalid type of data for this entry"
        list = (list...,v.first,v.second)
    end
    return list
end

"""
    StorePlan(sample_time,varlist[;htype=RegularHistory,min_time=-Inf,max_time=Inf])

Create a plan for storing history data. The storage of data is specied to occur
at a sample interval given by `sample_time`. Optionally, one can specify the
initial time `min_time` and final time `max_time` (included) for a sampling window.
These default to all times. The list of variables to be stored is
specified as a list of variables `varlist`, provided as comma-separated named pairs,
e.g. `"varname1"-> v1,"varname2"-> v2`. Tuple-type variables are unwrapped
into separate storage. The optional argument `htype` can be used to set the
history data to `PeriodicHistory` or `RegularHistory` (the default). In the
case of `PeriodicHistory`, the data is assumed to repeat with a period equal
to length(history)+1.
"""
struct StorePlan{H<:HistoryType}
    min_t::Float64
    max_t::Float64
    store_Δt::Float64
    vardict::Dict
    StorePlan(store_Δt,varlist...;htype=RegularHistory,min_time=-Inf,max_time=Inf) = new{htype}(min_time,max_time,store_Δt,_get_typedict(varlist))
end

"""
    initialize_storage(S::StorePlan) -> Vector

Initialize a storage data stack for the storage plan `S`. The output is
an empty vector of `History` vectors.
"""
function initialize_storage(S::StorePlan{H}) where {H}
    data = Dict{String,History}()
    for v in S.vardict
        get!(data,v.first,History(v.second,htype=H))
    end
    return data
end


"""
    store_data!(data,t,S::StorePlan,v)

Check whether time `t` is a time for saving for storage as described by plan `S`,
and if so, push the variables specified in `v` (a list of pairs) onto the `data` stack.
"""
function store_data!(data,t,S::StorePlan,v...)
  tol = 1e-8
  if t >= (S.min_t-tol) && t <= (S.max_t + tol) &&
      ((isapprox(mod(t,S.store_Δt),0,atol=tol) ||
        isapprox(mod(t,S.store_Δt),S.store_Δt,atol=tol)))
        _store_data!(data,S::StorePlan,v...)
  end
  return data
end


function _get_typedict(varlist)
    newdict = Dict{String,Type}()
    for l in varlist
        get!(newdict,l.first,typeof(l.second))
    end
    return newdict
end


function _store_data!(data,S::StorePlan,varlist...)
    for v in varlist
        @assert haskey(data,v.first) "No such variable exists in this list"
        @assert typeof(v.second) == S.vardict[v.first] "Invalid type of data for this entry"
        push!(data[v.first],v.second)
    end
    return data
end
