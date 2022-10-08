static uint32_t si_f0_fn_0(uint32_t v0, uint32_t v1);
static uint32_t si_f1_fn_1(uint32_t v0, uint32_t v1);

static uint32_t (*si_c0[])(uint32_t,uint32_t) = {si_f0_fn_0,si_f1_fn_1};

static uint32_t si_f0_fn_0(uint32_t v0, uint32_t v1) {
  return v0;
}

static uint32_t si_f1_fn_1(uint32_t v0, uint32_t v1) {
  return v1;
}

static uint32_t si_f2_sfn(bool v0, uint32_t v1, uint32_t v2) {
  uint32_t (*v3)(uint32_t,uint32_t) = si_c0[v0];
  uint32_t v4 = v3(v1, v2);
  return v4;
}

uint32_t (**const fn_arr)(uint32_t,uint32_t) = si_c0;

