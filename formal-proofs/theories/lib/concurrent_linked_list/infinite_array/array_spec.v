From iris.program_logic Require Import atomic.
From iris.heap_lang Require Export proofmode notation lang.

Record infiniteArraySpec Σ `{!heapG Σ} :=
  InfiniteArraySpec {
      newInfiniteArray: val;
      cancelCell: val;
      findCell: val;
      derefCellPointer: val;
      cutoffMoveForward: val;
      cutoffGetPointer: val;
      cellPointerId: val;
      infinite_array_name: Type;
      is_infinite_array (N: namespace) (γ: infinite_array_name)
                        (cell_is_owned: nat → iProp Σ): iProp Σ;
      is_infinite_array_persistent N γ co:
        Persistent (is_infinite_array N γ co);
      infinite_array_mapsto (N: namespace) (cell_is_owned: nat -> iProp Σ)
                            (γ: infinite_array_name) (i: nat) (ℓ: loc): iProp Σ;
      infinite_array_mapsto_persistent N co γ i ℓ:
        Persistent (infinite_array_mapsto N co γ i ℓ);
      infinite_array_mapsto_agree N co γ i ℓ ℓ':
        infinite_array_mapsto N co γ i ℓ -∗ infinite_array_mapsto N co γ i ℓ'
                              -∗ ⌜ℓ = ℓ'⌝;
      is_infinite_array_cell_pointer N (γ: infinite_array_name) (p: val) (i: nat):
          iProp Σ;
      is_infinite_array_cutoff_reading (N: namespace) (γ: infinite_array_name)
                                       (p: val) (start_id: nat): iProp Σ;
      is_infinite_array_cell_pointer_persistent N γ p i:
        Persistent (is_infinite_array_cell_pointer N γ p i);
      is_infinite_array_cutoff (N: namespace)
        (γ: infinite_array_name) (v: val) (start_index: nat): iProp Σ;
      cell_is_cancelled (N: namespace) (γ: infinite_array_name) (i: nat): iProp Σ;
      cell_is_cancelled_persistent N γ i: Persistent (cell_is_cancelled N γ i);
      cell_cancellation_handle
        (N: namespace) (γ: infinite_array_name) (i: nat): iProp Σ;
      cell_cancellation_handle_exclusive N γ i:
        cell_cancellation_handle N γ i -∗ cell_cancellation_handle N γ i -∗ False;
      cell_cancellation_handle_not_cancelled N γ i:
        cell_is_cancelled N γ i -∗ cell_cancellation_handle N γ i -∗ False;
      acquire_cell N cell_is_owned E γ i ℓ:
        ↑N ⊆ E →
        infinite_array_mapsto N cell_is_owned γ i ℓ ={E, E∖↑N}=∗
        ▷ (cell_is_owned i ∨ ℓ ↦ NONEV ∗ cell_cancellation_handle N γ i) ∗
        (▷ cell_is_owned i ={E∖↑N, E}=∗ True);
      newInfiniteArray_spec N co k:
        {{{ ⌜(k > 0)%nat⌝ ∧ inv_heap_inv }}}
          newInfiniteArray #k
        {{{ γ ℓ, RET #ℓ; is_infinite_array N γ co ∗
                        [∗ list] i ∈ seq 0 k,
                          is_infinite_array_cutoff N γ #(ℓ +ₗ Z.of_nat i) 0
        }}};
      cancelCell_spec N γ co p i:
        is_infinite_array N γ co -∗
        is_infinite_array_cell_pointer N γ p i -∗
        <<< cell_cancellation_handle N γ i >>>
            cancelCell p @ ⊤ ∖ ↑N
        <<< cell_is_cancelled N γ i, RET #() >>>;
      findCell_spec N γ co p (source_id id: nat):
        {{{ is_infinite_array N γ co ∗
            is_infinite_array_cutoff_reading N γ p source_id }}}
        findCell p #id @ ⊤
        {{{ p' id', RET p'; is_infinite_array_cell_pointer N γ p' id'
            ∗ ⌜(id ≤ id')%nat⌝
            ∗ ∀ i, (⌜max source_id id ≤ i < id'⌝)%nat -∗ cell_is_cancelled N γ i
        }}};
      derefCellPointer_spec N co γ (p: val) i:
        {{{ is_infinite_array N γ co ∗ is_infinite_array_cell_pointer N γ p i }}}
          derefCellPointer p
        {{{ ℓ, RET #ℓ; infinite_array_mapsto N co γ i ℓ }}};
      cutoffMoveForward_spec N co γ (p v: val) i:
        is_infinite_array N γ co -∗
        is_infinite_array_cell_pointer N γ p i -∗
        <<< ∀ start_index, ▷ is_infinite_array_cutoff N γ v start_index >>>
          cutoffMoveForward v p @ ⊤ ∖ ↑N
        <<< ∃ (success: bool), if success
            then ∃ i', ⌜start_index ≤ i' ≤ max i start_index⌝ ∧
                      is_infinite_array_cutoff N γ v i'
            else ▷ is_infinite_array_cutoff N γ v start_index, RET #success >>>;
      cutoffGetPointer_spec N γ (v: val):
        ⊢ <<< ∀ i, ▷ is_infinite_array_cutoff N γ v i >>>
          cutoffGetPointer v @ ⊤
        <<< ∃ (p: val), is_infinite_array_cutoff N γ v i ∗
                        is_infinite_array_cutoff_reading N γ p i, RET p >>>;
      cellPointerId_spec N co γ (p: val) i:
        {{{ is_infinite_array N γ co ∗ is_infinite_array_cell_pointer N γ p i }}}
          cellPointerId p
        {{{ RET #i; True }}};
    }.