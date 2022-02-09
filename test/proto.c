static int32_t si_f1(int32_t v0);

static int32_t si_f0(int32_t v0) {
  int32_t v1 = si_f1(v0);
  return v1;
}

static int32_t si_f1(int32_t v0) {
  int32_t v1 = oper(v0, 1);
  return v1;
}

int32_t (*const x)(int32_t v0) = si_f0;

