static int32_t si_f0(int32_t v0, int32_t v1) {
  int32_t v2 = add(v0, v1);
  return v2;
}

static int32_t si_f1(int32_t v0) {
  int32_t v1 = si_f0(v0, v0);
  return v1;
}

int32_t fn(int32_t v0) { return si_f1(v0); }

