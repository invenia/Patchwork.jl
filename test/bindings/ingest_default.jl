import Mocking: Bindings, ingest_default!

b = Bindings()
ingest_default!(b, :(1))
@test b.internal == Set()
@test b.external == Set()

b = Bindings()
ingest_default!(b, :Int)
@test b.internal == Set()
@test b.external == Set([:Int])

b = Bindings()
ingest_default!(b, :(f(rand(Bool))))
@test b.internal == Set()
@test b.external == Set([:f, :rand, :Bool])