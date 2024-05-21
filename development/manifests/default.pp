node default {
  lookup('classes', Array[String], { 'strategy' => 'deep', 'merge_hash_arrays' => true }, []).include
}
