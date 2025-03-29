pub type Vector2 {
  Vector2(
    x:Float,
    y:Float
  )
}

pub fn from_tuple(tup:#(Float,Float)) {
  Vector2(tup.0,tup.1)
}
