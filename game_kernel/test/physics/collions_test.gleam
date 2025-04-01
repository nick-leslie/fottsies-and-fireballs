import gleam/io
import gleam/list
import gleamy/bench
import physics/collisons
import raylib
import gleeunit
import gleeunit/should
import gleam/result

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn gjk_col_simple_test() {
  let a = raylib.Rectangle(1.0,0.0,1.0,1.0)
  let b = raylib.Rectangle(1.0,0.0,1.0,1.0)
  let check = collisons.rect_rect_gjk(a,b)
  check |> should.be_ok
}
pub fn gjk_no_col_test() {
  let a = raylib.Rectangle(10.0,0.0,1.0,1.0)
  let b = raylib.Rectangle(0.0,0.0,1.0,1.0)
  let check = collisons.rect_rect_gjk(a,b)
  check |> should.be_error
}
