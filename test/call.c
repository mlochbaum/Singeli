static int32_t si_f0_mid(int32_t v0_a, int32_t v1_b) {
  int32_t v2 = add(v0_a, v1_b);
  return v2;
}

static int32_t si_f1_fn(int32_t v0_a) {
  int32_t v1 = si_f0_mid(v0_a, v0_a);
  return v1;
}

int32_t (*const fn)(int32_t) = si_f1_fn;

