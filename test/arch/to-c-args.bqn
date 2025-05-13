#!/usr/bin/env bqn
feats ← ∾ ',' ((⊢-˜+`×¬)∘=⊔⊢)¨ •args
•Out 1↓ ∾' '⊸∾¨ (⟨feats, 1⟩ •Import "../../arch.bqn").GetCFlags @
