static int32_t si_f0_mid(int32_t v0, int32_t v1) {
  int32_t v2 = add(v0, v1);
  return v2;
}

static int32_t si_f1_fn(int32_t v0) {
  int32_t v1 = si_f0_mid(v0, v0);
  return v1;
}

int32_t (*const fn)(int32_t) = si_f1_fn;

