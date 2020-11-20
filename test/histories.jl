using CartesianGrids
using Statistics

@testset "Histories" begin

  a = 1.0
  b = 0.0
  c = 5.0

  h = History(collect(1:5))
  @test mean(h) == 3

  h = History(Nodes(Dual,(5,5)))
  d = Nodes(Dual,(5,5))
  fill!(d,a)
  push!(h,deepcopy(d))
  fill!(d,b)
  push!(h,deepcopy(d))
  fill!(d,c)
  push!(h,deepcopy(d))

  @test length(h.r) == length(h)

  dh = diff(h)

  @test typeof(dh) <: History

  @test dh[2][1,1] == c-b

  # test periodic history
  hp = History(h.vec,htype=PeriodicHistory)
  @test hp[4] == hp[1]

  # test the differencing of periodic history
  dhp = diff(hp)
  @test typeof(dhp) <: History
  @test dhp[1][1,1] == b-a
  @test dhp[5] == dhp[2]

  # test staggered indexing
  hp2 = History(hp[1:2:5],htype=PeriodicHistory)
  @test hp2[2][1,1] == c

  # test circular shifting
  hpshift = circshift(hp,1)
  @test hpshift[1][1,1] == c

  # testing arithmetic
  h3 = 3*h
  @test h3[3][1,1] == 3*c

  h4 = h+h3
  @test h4[1][1,1] == 4*a

  h5 = -h
  @test h5[3][1,1] == -c

  h6 = h/2
  @test h6[1][1,1] == a/2

  # test setting ghosts on regular history
  h_pre = deepcopy(h)
  h_post = deepcopy(h)
  set_first_ghost!(h,h_pre)
  @test h[1][1,1] == c

  set_last_ghost!(h,h_post)
  @test h[end][1,1] == a

  @test length(h) == length(h.r)+2
  @test h.r.start == 2
  @test h.r.stop == 4

end

@testset "Storage" begin

  u = ones(5,5)
  t = 0.0

  tsample = 0.05
  S = StorePlan(tsample,"state" => u, "time" => t)

  data_history = initialize_storage(S)

  store_data!(data_history,0.05,S,"state"=>deepcopy(u),"time"=>t)
  store_data!(data_history,0.1,S,"state"=>2*deepcopy(u),"time"=>2*t)
  store_data!(data_history,0.12,S,"state"=>3*deepcopy(u),"time"=>3*t)

  # test that we cannot pass the wrong type of data for one of the entries
  @test_throws AssertionError store_data!(data_history,0.15,S,"state"=>t,"time"=>t)

  # test that we cannot pass the wrong name of data for one of the entries
  @test_throws AssertionError store_data!(data_history,0.15,S,"another"=>u,"time"=>t)

  @test length(data_history) == 2

  @test data_history["state"][2] == 2*u
  @test data_history["time"][2] == 2*t


end

@testset "Interpolations" begin

  u0 = ones(5,5)
  xg, yg = 0:1:4, 0:1:4
  t = 0.0
  u = deepcopy(u0)

  t_sample = 0.05

  S = StorePlan(t_sample,"state" => u0, "time" => t)

  data_history = initialize_storage(S)

  store_data!(data_history,t,S,"state"=>deepcopy(u),"time"=>t)

  for i in 1:100
    u .+= u0 # simple model, just for making it dynamic
    t += 0.01
    store_data!(data_history,t,S,"state"=>u,"time"=>t)
  end
  tr = data_history["time"][1]:t_sample:data_history["time"][end]

  ui = interpolated_history(data_history["state"],xg,yg,tr)

  @test ui(0.5,0.4,0.54) ≈ 55.0

end
