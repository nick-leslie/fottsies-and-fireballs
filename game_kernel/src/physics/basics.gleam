import physics/vector2

//todo refactor with this
pub type RiggdBody {
  RiggdBody(
    pos:vector2.Vector2,
    vel:vector2.Vector2
  )
}

pub fn move_by(r:RiggdBody,vec:vector2.Vector2) {
  RiggdBody(
    ..r,
    pos: vector2.Vector2(r.pos.x +. vec.x,r.pos.y +. vec.y)
  )
}
