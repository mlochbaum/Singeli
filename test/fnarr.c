static uint32_t si_f0_fn_0(uint32_t v0_a, uint32_t v1_b);
static uint32_t si_f1_fn_1(uint32_t v0_a, uint32_t v1_b);

static uint32_t (*si_c0_fns[])(uint32_t,uint32_t) = {si_f0_fn_0,si_f1_fn_1};

static uint32_t si_f0_fn_0(uint32_t v0_a, uint32_t v1_b) {
  return v0_a;
}

static uint32_t si_f1_fn_1(uint32_t v0_a, uint32_t v1_b) {
  return v1_b;
}

static uint32_t si_f2_sfn(bool v0_i, uint32_t v1_a, uint32_t v2_b) {
  uint32_t (*v3)(uint32_t,uint32_t) = si_c0_fns[v0_i];
  uint32_t v4 = v3(v1_a, v2_b);
  return v4;
}

uint32_t (**const fn_arr)(uint32_t,uint32_t) = si_c0_fns;

