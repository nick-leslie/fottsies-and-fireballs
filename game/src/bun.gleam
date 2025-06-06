import gleam/javascript/promise

@external(javascript, "./bun_ffi.mjs", "generate_heap_snapshot")
pub fn generate_heap_snapshot() -> promise.Promise(Nil)


@external(javascript, "./bun_ffi.mjs", "heap_stats")
pub fn heap_stats() -> Nil
