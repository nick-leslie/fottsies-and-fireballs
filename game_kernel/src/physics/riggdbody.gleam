import physics/vector2

//todo refactor with this
pub type RiggdBody {
  RiggdBody(
    pos:vector2.Vector2,
    vel:vector2.Vector2,
    force:vector2.Vector2,
    mass:Float
  )
}

pub fn new(pose pos,mass mass) {
  RiggdBody(
    pos:,
    vel:vector2.zero(),
    force:vector2.zero(),
    mass:,
  )
}

pub fn move_by(r:RiggdBody,vec:vector2.Vector2) {
  RiggdBody(
    ..r,
    pos: vector2.Vector2(r.pos.x +. vec.x,r.pos.y +. vec.y)
  )
}
pub fn move_by_vel(r:RiggdBody) {
  RiggdBody(
    ..r,
    pos: vector2.add(r.pos,r.vel)
  )
}

pub fn add_force(r:RiggdBody,force:vector2.Vector2) {
  RiggdBody(
    ..r,
    force: vector2.add(r.force,force)
  )
}
pub fn sub_force(r:RiggdBody,force:vector2.Vector2) {
  RiggdBody(
    ..r,
    force: vector2.sub(r.force,force)
  )
}

pub fn set_vel(r,vel) {
  RiggdBody(
    ..r,
    vel:
  )
}


pub fn step(r:RiggdBody) {
  let force = vector2.scale_div(r.force,r.mass)
  let vel = vector2.add(r.vel,force)
  RiggdBody(
    ..r,
    force:,
    vel:
  )
}
