static uint32_t si_f0(uint32_t v0, uint32_t v1);
static uint32_t si_f1(uint32_t v0, uint32_t v1);

static uint32_t (*si_c0[])(uint32_t,uint32_t) = {si_f0,si_f1};

static uint32_t si_f0(uint32_t v0, uint32_t v1) {
  return v0;
}

static uint32_t si_f1(uint32_t v0, uint32_t v1) {
  return v1;
}

uint32_t (**const fn_arr)(uint32_t,uint32_t) = si_c0;

