import player
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
// pub fn gjk_col_simple_test() {
//   let a = raylib.Rectangle(1.0,0.0,1.0,1.0)
//   let b = raylib.Rectangle(1.0,0.0,1.0,1.0)
//   let check = collisons.rect_rect_gjk(a,b)
//   check |> should.be_ok
// }
const sprite_scale = 3.0
pub fn gjk_col_complex_test() {
  let player_col = player.make_player_world_box(
    xy:#(500.0 *. sprite_scale,200.0 *.sprite_scale),
    wh:#(10.0 *. sprite_scale,10.0*. sprite_scale
  )) |> echo
  let b = raylib.Rectangle(
    width:1000.0,
    height:50.0,
    x:100.0,
    y:700.0,
  ) |> echo
  let check = collisons.rect_rect_gjk(player_col.box,b)
  check |> should.be_error
}
// pub fn gjk_no_col_test() {
//   let a = raylib.Rectangle(10.0,10.0,1.0,1.0)
//   let b = raylib.Rectangle(10.0,10.0,20.0,1.0)
//   let check = collisons.rect_rect_gjk(a,b)
//   check |> should.be_error
// }
