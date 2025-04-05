pub type Vector2 {
  Vector2(
    x:Float,
    y:Float
  )
}

pub fn from_tuple(tup:#(Float,Float)) {
  Vector2(tup.0,tup.1)
}
pub fn to_tuple(vec:Vector2) {
  #(vec.x,vec.y)
}

pub fn inverse(a:Vector2,) {
  Vector2(
    x: a.x *. -1.0,
    y: a.y *. -1.0
  )
}
pub fn add(a:Vector2,b:Vector2) {
  Vector2(
    x: a.x +. b.x,
    y: a.y +. b.y
  )
}

pub fn dot(a:Vector2, b:Vector2) {
 a.x *. b.x +. a.y *. b.y
}

pub fn cross(a:Vector2,b:Vector2) {
  Vector2(
    x: a.y *. 0.0 -. 0.0 *. b.y,
    y: 0.0 *. b.x -. a.x *. 0.0,
  )
}



pub fn sub(a:Vector2,b:Vector2) {
  Vector2(
    x: a.x -. b.x,
    y: a.y -. b.y
  )
}
