static int32_t si_f1_fun_1(int32_t v0_x);

static int32_t si_f0_x(int32_t v0_a) {
  int32_t v1 = si_f1_fun_1(v0_a);
  return v1;
}

static int32_t si_f1_fun_1(int32_t v0_x) {
  int32_t v1 = oper(v0_x, 1);
  return v1;
}

int32_t (*const x)(int32_t) = si_f0_x;

