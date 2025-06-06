import { generateHeapSnapshot } from "bun";
import { heapStats } from "bun:jsc";


export async function generate_heap_snapshot() {
  const snapshot = generateHeapSnapshot();
  await Bun.write("heap.json", JSON.stringify(snapshot, null, 2));
}


export function heap_stats() {
  console.log(heapStats());
}
