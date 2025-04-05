 /**
  * GJK (Gilbert-Johnson-Keerthi) Algorithm for collision detection.
  *
  * This implementation focuses on detecting whether two convex shapes are
  * colliding.  It does NOT calculate the penetration depth or collision normal.
  *
  * @param {Function} supportA - Support function for shape A (returns the
  *                             farthest point in shape A along a given direction).
  * @param {Function} supportB - Support function for shape B.
  * @returns {boolean} True if the shapes are colliding, false otherwise.
  */
 function gjk(supportA, supportB) {
  /**
   * Calculates the Minkowski difference support point.
   *
   * @param {Vec2} direction - The direction to search along.
   * @returns {Vec2} The support point (A - B) along the given direction.
   */
  function support(direction) {
    const pointA = supportA(direction);
    const pointB = supportB({ x: -direction.x, y: -direction.y }); // Reverse direction for B
    return { x: pointA.x - pointB.x, y: pointA.y - pointB.y };
  }


  // 1. Initialization
  let simplex = [];
  let direction = { x: 1, y: 0 }; // Initial search direction (arbitrary)
  simplex.push(support(direction));


  // 2. Iteration
  for (let i = 0; i < 100; ++i) {
    // Limit iterations to prevent infinite loops
    let last = simplex[simplex.length - 1];
    direction = { x: -last.x, y: -last.y }; // Point towards the origin

    let newPoint = support(direction);
    if (dotProduct(newPoint, direction) <= 0) {
      return false; // No collision (new point not past the origin)
    }

    simplex.push(newPoint);

    if (containsOrigin(simplex)) {
      return true; // Collision detected
    }
  }


  console.warn("GJK Algorithm: Maximum iterations reached.  May not be accurate.");
  return false; // Indicate potential non-collision after max iterations
 }


 /**
  * Calculates the dot product of two vectors.
  *
  * @param {Vec2} a
  * @param {Vec2} b
  * @returns {number} The dot product of a and b.
  */
 function dotProduct(a, b) {
  return a.x * b.x + a.y * b.y;
 }


 /**
  * Determines if the simplex contains the origin.  This is the heart of the GJK algorithm.
  * Reduces the simplex to a line or triangle, if possible, while still containing the origin.
  *
  * @param {Vec2[]} simplex - Array of points representing the simplex.
  * @returns {boolean} True if the origin is contained within the simplex.
  */
 function containsOrigin(simplex) {
  switch (simplex.length) {
  case 2:
  return lineCase(simplex);
  case 3:
  return triangleCase(simplex);
  default:
  return false; // Should not happen in this implementation (max 3 points)
  }
 }


 /**
  * Handles the line case (simplex contains two points).
  * Determines if the origin lies on the line segment formed by the two points.
  *
  * @param {Vec2[]} simplex - Array containing two points.
  * @returns {boolean} True if the origin is on the line segment.
  */
 function lineCase(simplex) {
  let a = simplex[1];
  let b = simplex[0];


  let ab = { x: b.x - a.x, y: b.y - a.y };
  let ao = { x: -a.x, y: -a.y };


  let abDotAo = dotProduct(ab, ao);
  let abDotAb = dotProduct(ab, ab);


  if (abDotAo <= 0) {
  simplex.length = 1; // Reduce to point A
  return false;
  }


  if (abDotAo >= abDotAb) {
  simplex.length = 1; //Reduce to point B by setting length and updating first element
  simplex[0] = b;
  return false;
  }


  return true; // Origin is on the line segment.  Collision!
 }


 function triangleCase(simplex) {
  let a = simplex[2];
  let b = simplex[1];
  let c = simplex[0];

  let ab = { x: b.x - a.x, y: b.y - a.y };
  let ac = { x: c.x - a.x, y: c.y - a.y };
  let ao = { x: -a.x, y: -a.y };

  // 1. Check region AB
  let abPerp = { x: -ab.y, y: ab.x }; // Perpendicular to AB, pointing outwards
  if (dotProduct(abPerp, ao) > 0) {
  // Origin is outside AB, reject point C
  simplex.shift(); // Remove c from simplex array
  return false;
  }

  //Reassign values of points in the simplex because c might have been removed
   a = simplex[1];
   b = simplex[0];
   ab = { x: b.x - a.x, y: b.y - a.y };
   ao = { x: -a.x, y: -a.y };


  // 2. Check region AC
  let acPerp = { x: -ac.y, y: ac.x }; // Perpendicular to AC, pointing outwards
  if (dotProduct(acPerp, ao) > 0) {
  // Origin is outside AC, reject point B
  simplex.splice(1,1); // Remove b from simplex array
  return false;
  }


  // Origin is inside the triangle
  return true;
 }



 // Example usage (assuming you have defined support functions)


 /**
  * Example support function for a circle.
  *
  * @param {number} radius - Radius of the circle.
  * @param {Vec2} center - Center of the circle.
  * @param {Vec2} direction - The direction to search along.
  * @returns {Vec2} The support point.
  */
 function circleSupport(radius, center, direction) {
  // Normalize the direction vector
  let length = Math.sqrt(direction.x * direction.x + direction.y * direction.y);
  let normalizedDirection = { x: direction.x / length, y: direction.y / length };


  return {
  x: center.x + normalizedDirection.x * radius,
  y: center.y + normalizedDirection.y * radius,
  };
 }




 // Example Usage (assuming Vec2 is {x: number, y: number})


 // Define support functions for two circles
 const circleA = { radius: 1, center: { x: 0, y: 0 } };
 const circleB = { radius: 1, center: { x: 2, y: 0 } };

function point_support(dir, points) {
   /**
    * Calculates the dot product of two vectors.
    *
    * @param {Vector2} v1 - The first vector.
    * @param {Vector2} v2 - The second vector.
    * @returns {number} The dot product of the two vectors.
    */
   function dot(v1, v2) {
     return v1.x * v2.x + v1.y * v2.y;
   }

   let furthest_point = points[0];
   let max_dist = dot(furthest_point, dir);
   for (const point of points) {
     const new_dist = dot(point, dir);
     if (new_dist >= max_dist) {
       furthest_point = point;
       max_dist = new_dist;
     }
   }

   return furthest_point;
 }
const sprite_scale = 3.0
const rectA = { width: 10 * sprite_scale,height:10*sprite_scale,  x: 10*sprite_scale, y: 200.0 * sprite_scale  };
const rectB = { width: 1000.0,height:50.0,  x: 0, y: 1000.0  };
console.log(rect_to_points(rectA))
console.log(rect_to_points(rectB))
console.log(point_support({x:0.0,y:-1.0},rect_to_points(rectA)))

 function rect_to_points(rect) {
  return [
    { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2},
    { x: rect.x - rect.width / 2, y: rect.y - rect.height / 2},
    { x: rect.x + rect.width / 2, y: rect.y - rect.height / 2},
    { x: rect.x - rect.width / 2, y: rect.y + rect.height / 2},
  ]
 }

 const supportA = (direction) => circleSupport(circleA.radius, circleA.center, direction);
 const supportB = (direction) => circleSupport(circleB.radius, circleB.center, direction);
 const supportABOX = (direction) => {
  return point_support(direction, rect_to_points(rectA))
 }
 const supportBBOX = (direction) => {
  let point = point_support(direction, rect_to_points(rectB))
  return point
 }


 // Detect collision using GJK
 const colliding = gjk(supportABOX, supportBBOX);


 console.log("Circles are colliding:", colliding); // Output: Circles are colliding: true
