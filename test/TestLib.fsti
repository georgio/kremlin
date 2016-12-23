module TestLib

open FStar.ST
open FStar.Buffer

val touch: Int32.t -> Stack unit (fun _ -> true) (fun _ _ _ -> true)
val check: Int32.t -> Int32.t -> Stack unit (fun _ -> true) (fun _ _ _ -> true)
val compare_and_print: buffer Int8.t -> buffer UInt8.t -> buffer UInt8.t -> UInt32.t ->
  Stack unit
  (requires (fun h -> True))
  (ensures  (fun h0 _ h1 -> True))

(* This function is for testing purposes only: this is an unmanaged, raw
 * pointer that cannot be freed. *)
val unsafe_malloc: l:UInt32.t -> 
  Stack (buffer UInt8.t)
    (fun _ -> true)
    (fun h0 b h1 -> live h1 b /\ ~(contains h0 b) /\ length b = FStar.UInt32.v l
      /\ HyperStack.is_eternal_region (frameOf b)
      /\ HyperStack.modifies (Set.singleton (frameOf b)) h0 h1
      /\ HyperStack.modifies_ref (frameOf b) (TSet.empty) h0 h1
      /\ (FStar.HyperStack.(Map.domain h0.h == Map.domain h1.h)))
val perr: FStar.UInt32.t -> Stack unit
  (requires (fun h -> true))
  (ensures (fun h0 _ h1 -> h0 == h1))
val print_clock_diff: C.clock_t -> C.clock_t -> Stack unit
  (requires (fun h -> true))
  (ensures (fun h0 _ h1 -> h0 == h1))

val uint8_p_null: buffer UInt8.t
val uint32_p_null: buffer UInt32.t
val uint64_p_null: buffer UInt64.t

type cycles
val cpucycles: unit -> Stack cycles
  (requires (fun h -> true))
  (ensures (fun h0 _ h1 -> h0 == h1))
val print_cycles_per_round: cycles -> cycles -> FStar.UInt32.t -> Stack unit
  (requires (fun h -> true))
  (ensures (fun h0 _ h1 -> h0 == h1))
