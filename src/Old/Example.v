Require Import Frame FormTop.FormTop FrameVal.

(** If we view [F.prop] as locale corresponding to the 1-point set, then
    [unit_prop] is the unique probability distribution we can define for the 1-point 
    set; it puts all its mass (i.e., a measure of 1) on that single point. *)

Require Import LPReal Ring Algebra.Sets.
Local Open Scope Ensemble.

Definition unit_prop : Val.t One.FrameOne.
Proof.
refine (
  {| Val.val := fun P => LPRindicator (P I) |}
); simpl; intros.
- apply LPRind_false. unfold not. intros. destruct H.
  contradiction.
- unfold L.le in H. simpl in H. apply LPRind_imp. 
  unfold FormTop.leA, FormTop.Sat, One.Cov in *. 
  unfold Included, In in H.
  apply H. constructor.
- rewrite (LPRind_iff (FormTop.minA _ _ _ _) (U I /\ V I)). 
  rewrite (LPRind_iff ((U ∪ V) I) (U I \/ V I)).
  rewrite (SRadd_comm LPRsrt (LPRindicator (U I \/ V I))).
  apply LPRind_modular.
  unfold FormTop.down. simpl. split; intros.
  destruct H; auto. destruct H; [left | right]; auto.
  unfold FormTop.minA. split; intros. destruct H. 
  destruct H, H0. unfold Basics.flip in *. 
  destruct a, a0, b. auto.
  destruct H. repeat (econstructor; try eassumption).
- unfold Val.ContinuousV. intros. simpl.
  apply LPRle_antisym. unfold LPRle.
  intros. simpl in *. destruct H. destruct H.
  exists i; auto.
  unfold LPRle. intros. simpl in *. destruct H.
  destruct H. split. econstructor; eassumption. assumption.
Defined.

Definition point {A} (x : A) : F.point (FormTop.FOps Logic.eq (Discrete.Cov A)).
Proof.
pose proof (@One.toFPoint A eq eq (PO.discrete A) (Discrete.Cov A)
  (Discrete.isCov A)).
specialize (X (fun x' => x' = x)).
apply X.
unfold One.Point. simpl.
constructor; unfold One.Cov, Discrete.Cov; intros.
- exists x. reflexivity.
- assumption.
- subst. exists x. split. split; reflexivity. reflexivity.
- exists b. auto.
Defined.

Section OTPExample.

Variable A : Type.
Hypothesis deceqA : forall a a' : A, {a = a'} + {a <> a'}.

Let Cov := Discrete.Cov A.

Instance POA : PO.t Logic.eq Logic.eq := PO.discrete A.

Instance opsA : Frame.Ops (A -> Prop) := FormTop.FOps Logic.eq Cov.
Instance frameA : Frame.t (A -> Prop) opsA := FormTop.Frame Logic.eq Cov _
  (Discrete.isCov A).

Require Fin.
Import ValNotation.

Fixpoint finToVec {A} {n} : (Fin.t n -> A) -> Vector.t A n := match n with
  | 0 => fun _ => Vector.nil A
  | S n' => fun f => let ans := finToVec (fun x => f (Fin.FS x)) in
     Vector.cons A (f Fin.F1) _ ans
  end.

Definition uniformF {n : nat} (f : Fin.t (S n) -> A)
  := Val.uniform (finToVec (fun i => point (f i))).

End OTPExample.

Definition CovB := Discrete.Cov bool.
Instance OB : Frame.Ops (bool -> Prop) := FormTop.FOps Logic.eq CovB.
Instance PreOB : PreO.t Logic.eq := PreO.discrete bool.
Instance FB : Frame.t (bool -> Prop) OB := FormTop.Frame Logic.eq CovB (PreO.discrete bool) (Discrete.isCov bool).
Instance FTB : FormTop.t Logic.eq CovB := Discrete.isCov bool.

Require Import Qnn.
Local Open Scope LPR.
Import ValNotation.

Definition coin (p : Qnn) : Val.t FB :=
  (LPRQnn p * Val.unit (point true) + LPRQnn (1 - p)%Qnn * Val.unit (point false))%Val.

Definition faircoin := coin Qnnonehalf. 

Definition bfunc (f : bool -> bool) : Frame.cmap OB OB :=
  Cont.toCmap FTB FTB (Discrete.discrF f) (Discrete.fCont f).

Lemma LPRpluseq : forall (p a b a' b' : LPReal),
  a = a' -> b = b' ->
  (p * b + p * a = p * a' + p * b')%LPR.
Proof.
intros. subst. ring.
Qed.

Lemma LPRpluseq2 : forall (p a b a' b' : LPReal),
  a = a' -> b = b' ->
  (p * a + p * b = p * a' + p * b')%LPR.
Proof.
intros. subst. ring.
Qed.

Theorem reverse : forall (p : Qnn) (peven : (p = 1 - p)%Qnn),
  coin p = Val.map (bfunc negb) (coin p).
Proof.
intros. apply Val.eq_compat. unfold Val.eq.
intros. simpl. rewrite <- peven. clear peven.
unfold Cont.frame. 
apply LPRpluseq; apply LPRind_iff. 
- split; intros.
  + destruct H as (t' & Pt' & tt').
    subst. exists true. split. exists false. split. assumption. constructor.
    reflexivity.
  + destruct H as ([] & ([] & Pt & discr) & ttrue);
    exists false; inversion discr; auto. congruence.
- split;intros. 
  + destruct H as (t' & Pt' & tt').
    subst. exists false. split. exists true. split. assumption. constructor.
    reflexivity.
  + destruct H as ([] & ([] & Pt & discr) & ttrue);
    exists true; inversion discr; auto. congruence.
Qed.

Require Import Qcanon.
Close Scope Qc.
Lemma phalf : (Qnnonehalf = 1 - Qnnonehalf)%Qnn.
Proof.
apply Qnneq_prop. unfold Qnneq. apply Qceq_alt.
reflexivity. 
Qed.

Require Import FunctionalExtensionality.
Theorem OTP : forall (b : bool),
  Val.map (bfunc (xorb b)) faircoin = faircoin.
Proof.
intros. symmetry. destruct b. change (xorb true) with negb.
apply reverse. simpl. apply Qnneq_prop. unfold Qnneq. apply Qceq_alt.
reflexivity. 
replace (xorb false) with (@id bool).
simpl. unfold bfunc. apply Val.eq_compat. unfold Val.eq; intros.
simpl.
rewrite <- phalf.
apply LPRpluseq2; apply LPRind_iff; unfold Cont.frame.
- split; intros.
  + destruct H as (t & Pt & eqt). subst. exists true. split.
    exists true. split. assumption. constructor. reflexivity.
  + destruct H as ([] & ([] & Pt & discr) & ttrue);
    exists true; inversion discr; auto. congruence.
- split; intros.
  + destruct H as (t' & Pt' & tt').
    subst. exists false. split. exists false. split. assumption. constructor.
    reflexivity.
  + destruct H as ([] & ([] & Pt & discr) & ttrue);
    exists false; inversion discr; auto. congruence.
- apply functional_extensionality.
  intros []; reflexivity.
Qed.


Section Finite.
Require Finite.

Instance DOps A : Frame.Ops (A -> Prop) := FormTop.FOps Logic.eq (Discrete.Cov A).

Instance DiscretePreO (A : Type) :  @PreO.t A eq := PreO.discrete A.
Instance DiscreteFrame (A : Type) : F.t (A -> Prop) (opsA A) := frameA A.


Definition Ffunc {A B} (f : A -> B) : Frame.cmap (DOps A) (DOps B) :=
  Cont.toCmap (Discrete.isCov A) (Discrete.isCov B) (Discrete.discrF f) (Discrete.fCont f).

Fixpoint build_finite {A : Type} (fin : Finite.T A) : (A -> LPReal) -> Val.t (frameA A)
  := match fin with
  | Finite.F0 => fun _ => 0%Val
  | Finite.FS _ fin' => fun f =>
     (f (inl I) * Val.unit (point (inl I)) 
     + Val.map (Ffunc inr) (build_finite fin' (fun x => f (inr x))))%Val
  | Finite.FIso _ _ fin' t => fun f =>
     Val.map (Ffunc (Iso.to t)) (build_finite fin' (fun x => f (Iso.to t x)))
  end.

Definition build_finite_prod {A B} (fin : Finite.T (A * B))
  (f : A -> LPReal) (g : B -> LPReal) :=
  build_finite fin (fun z => let (x, y) := z in (f x * g y)%LPR).

Lemma discrete_inj {A B} (f : A -> B) (inj_f : forall x y, f x = f y -> x = y) (x : A) : 
  L.eq (eq x) (Cont.frame (Discrete.discrF f) (eq (f x))).
Proof.
simpl. unfold FormTop.eqA, FormTop.Sat, Discrete.Cov, Cont.frame,
  Discrete.discrF. intros; split; intros. subst.
  exists (f s). auto. destruct H as (t' & fx & fs). 
  apply inj_f. congruence.
Qed.


Lemma discrete_subset : forall {A B} (f : A -> B) a b,
  Cont.frame (Discrete.discrF f) (eq b) a <-> f a = b.
Proof.
intros. unfold Cont.frame, Discrete.discrF.
split; intros. destruct H as (t' & bt' & fat'). congruence.
exists b. auto.
Qed.

Lemma build_finite_char {A} (fin : Finite.T A) (f : A -> LPReal)
  (P : A -> Prop) : build_finite fin f P = sum_finite_subset fin P f.
Proof.
induction fin. 
- simpl. reflexivity.
- simpl. unfold Cont.frame. rewrite IHfin.
  rewrite (SRmul_comm LPRsrt (f (inl I))).
  apply LPRpluseq3. apply LPRind_iff.
  split; intros. destruct H as (t' & Ptt & tinl).
  subst. assumption. exists (inl I). auto.
  assert (forall f g, f = g -> sum_finite fin f = sum_finite fin g) by
   (intros; subst; auto).
  apply H. clear H. apply functional_extensionality. intros.
  apply LPRmult_eq_compat. apply LPRind_iff. unfold Discrete.discrF.
  split; intros. destruct H as (t & Pt & inrt). subst. assumption.
  exists (inr x). auto. auto.
- simpl. rewrite IHfin. 
    assert (forall f g, f = g -> sum_finite fin f = sum_finite fin g) by
   (intros; subst; auto).
  apply H. clear H. apply functional_extensionality. intros.
  apply LPRmult_eq_compat. apply LPRind_iff. unfold Cont.frame, Discrete.discrF.
  split; intros. destruct H as (t' & Pt' & tt').
  subst. assumption. exists (Iso.to t x). auto. auto.
Qed.

Definition build_finite_ok {A} (fin : Finite.T A) (f : A -> LPReal) (x : A) :
  build_finite fin f (eq x) = f x.
Proof. 
induction fin.
- contradiction. 
- destruct x.
  + destruct t. simpl. unfold Cont.frame.
    rewrite LPRind_true.
    erewrite Val.val_iff. rewrite Val.strict. ring.
    simpl. unfold FormTop.eqA, FormTop.supA, FormTop.Sat, Discrete.Cov.
    intros s. split; intros.
    destruct H as (t' & int' & invt').
    induction invt'. congruence. destruct H. contradiction.
    eexists; auto.
  + simpl. rewrite LPRind_false.
    rewrite <- discrete_inj.
    rewrite IHfin. ring. congruence.
    unfold not. unfold Cont.frame. intros.
    destruct H as (t' & inrt' & inlt'). congruence.
- rewrite <- (Iso.to_from t x) at 1. simpl.
  rewrite <- (discrete_inj (Iso.to t)).
  rewrite IHfin. rewrite Iso.to_from. reflexivity.
  intros. rewrite <- (Iso.from_to t). rewrite <- H.
  rewrite (Iso.from_to t). reflexivity.
Qed.

(** With the right principles this should become easy. *)
Lemma fin_char {A : Type} : forall (fin : Finite.T A) (mu : Val.t (frameA A)),
  mu = build_finite fin (fun a => mu (eq a)).
Proof.
intros. induction fin; apply Val.eq_compat; unfold Val.eq; simpl; intros P.
- erewrite Val.val_iff. apply Val.strict. simpl. 
  unfold FormTop.eqA, FormTop.supA, FormTop.Sat, Discrete.Cov.
  intros s. contradiction.
Admitted.

Lemma build_finite_extensional_f:
  forall (A : Type) (fin : Finite.T A) (f g : A -> LPReal) (P : A -> Prop),
  (forall x, f x = g x) ->
  (build_finite fin f) P = (build_finite fin g) P.
Proof.
intros. induction fin.
- simpl. reflexivity.
- simpl. erewrite IHfin.
  apply LPRplus_eq_compat. rewrite H. reflexivity.
  reflexivity. simpl. intros. apply H.
- simpl. specialize (IHfin (fun x => f (Iso.to t x))
   (fun x => g (Iso.to t x))).
  apply IHfin. intros. apply H.
Qed.

Lemma fin_dec {A : Type} : forall (fin : Finite.T A)
  (mu nu : Val.t (frameA A))
  , (forall (a : A), mu (eq a) = nu (eq a))
  -> mu = nu.
Proof.
intros. rewrite (fin_char fin mu). rewrite (fin_char fin nu).
apply functional_extensionality in H. rewrite H. reflexivity.
Qed.

End Finite.

Section OneTimePad.

Context {n : nat}.

Let N := Z.of_nat (S n). 
  Definition ring_theory_modulo := @Fring_theory N.
  Definition ring_morph_modulo := @Fring_morph N.
  Definition morph_div_theory_modulo := @Fmorph_div_theory N.
  Definition power_theory_modulo := @Fpower_theory N.

  Add Ring GFring_Z : ring_theory_modulo
    (morphism ring_morph_modulo,
     constants [Fconstant],
     div morph_div_theory_modulo,
     power_tac power_theory_modulo [Fexp_tac]).

Theorem perm : forall (x z : F N), exists (y : F N),
  (x + y = z)%F.
Proof.
intros. exists (z - x)%F. ring.
Qed.

Definition plus2 (p : F N * F N) : F N := let (x, y) := p
  in (x + y)%F.

Definition iso : Iso.T (F N) (Fin.t (S n)) := finiteF n.

Lemma finiteFN : Finite.T (F N).
Proof.
eapply Finite.FIso. 2: eapply Iso.Sym; apply iso.
apply Finite.fin.
Defined.

Definition uniformFN : Val.t (frameA (F N)) :=
  build_finite finiteFN (fun _ => LPRQnn (Qnnfrac (S n))).

Definition uniformFN' : Val.t (frameA (F N)) := uniformF (F N) (Iso.from iso).

Theorem iso_uniform {A} (fin : Finite.T A) : forall f g c,
  (forall a, f (g a) = a)
  -> (forall a, g (f a) = a)
  -> Val.map (Ffunc f) (build_finite fin (fun _ => c))
    = build_finite fin (fun _ => c).
Proof.
intros. apply (fin_dec fin). intros.
simpl. rewrite build_finite_ok.
rewrite <- (H a).
rewrite <- discrete_inj.
rewrite build_finite_ok. reflexivity.
intros. rewrite <- (H0 x). rewrite <- (H0 y). f_equal. 
assumption.
Qed.

Theorem OPTFN : forall (x : F N),
  Val.map (Ffunc (fun y => x + y))%F uniformFN = uniformFN.
Proof.
intros. apply (iso_uniform _ _ (fun y => y - x)%F);
  intros; ring.
Qed.

Lemma map_build_finite {A B} {finA : Finite.T A} {finB : Finite.T B}
  : forall (f : A -> B) (mu : Val.t (frameA A)) y
  , let _ : F.t (B -> Prop) (DOps B) := frameA B in
    Val.map (Ffunc f) mu (eq y)
  = sum_finite_subset finA (fun x => f x = y) (fun x => mu (eq x)).
Proof.
intros. simpl. rewrite (fin_char finA mu) at 1.
rewrite build_finite_char.
    assert (forall f g, f = g -> sum_finite finA f = sum_finite finA g) by
   (intros; subst; auto).
apply H; clear H; apply functional_extensionality; intros a.
apply LPRmult_eq_compat; try reflexivity. apply LPRind_iff.
apply discrete_subset.
Qed.

Definition finiteFN2 : Finite.T (F N * F N) := 
  Finite.times finiteFN finiteFN.

Theorem group_action_l : forall z, 
  Iso.T (sig (fun p : F N * F N => plus2 p = z)) (F N).
Proof.
intros.
assert (forall x, plus2 (x, z - x) = z)%F as eqprf.
intros. unfold plus2. ring.
 refine (
  {| Iso.to := fun p : (sig (fun p' => plus2 p' = z)) => let (x, y) := projT1 p in (z - y)%F
   ; Iso.from := fun x => exist _ (x, z - x)%F (eqprf x)
  |}).
- intros. apply Iso.sig_eq. intros. apply UIP_dec. apply F_eq_dec.
  simpl. destruct a. simpl. destruct x. simpl. unfold plus2 in e. rewrite <- e.
  f_equal; ring.
- intros. simpl. ring.
Defined.

Lemma discrF_identity {A} : forall U (f : A -> A), (forall a, f a = a)
 -> @L.eq _ (@F.LOps _ (DOps A)) (Cont.frame (Discrete.discrF f) U) U.
Proof.
intros. simpl. unfold FormTop.eqA, Discrete.Cov, Discrete.discrF,
  FormTop.Sat, Cont.frame.
intros s. split; intros. destruct H0 as (t & Ut & fst).
rewrite <- H. rewrite fst. assumption.
exists (f s). split. rewrite H. assumption. reflexivity.
Qed.

Lemma discrete_inj_e :
  forall (A B : Type) (f : A -> B),
  (forall x y : A, f x = f y -> x = y) ->
  forall x y, f x = y
  -> @L.eq _ (@F.LOps _ (DOps A)) (eq x) (Cont.frame (Discrete.discrF f) (eq y)).
Proof.
intros. rewrite <- H0. apply discrete_inj.
assumption.
Qed.

Theorem OTPGood : forall f,
  sum_finite finiteFN f = 1%LPR ->
  Val.map (Ffunc plus2) 
    (build_finite_prod finiteFN2
    f (fun _ => LPRQnn (Qnnfrac (S n)))) = uniformFN.
Proof.
intros. apply fin_dec. apply finiteFN.
intros x. unfold uniformFN. rewrite build_finite_ok.
unfold build_finite_prod. rewrite (@map_build_finite _ _ finiteFN2 finiteFN).
rewrite (sum_finite_subset_dec_equiv _ _ (fun x => F_eq_dec _ _)).
rewrite (sum_finite_iso _ _ (group_action_l x)). 
erewrite sum_finite_equiv. 
Focus 2. intros.  simpl. 
erewrite Val.val_iff.
rewrite build_finite_ok. Focus 2.
symmetry.
apply discrete_inj_e. intros. destruct x0, y.
congruence. 
instantiate (1 := existT (fun _ => F N) a (x - a)%F).
simpl. reflexivity. simpl. reflexivity.
unfold Cont.frame, Discrete.discrF.
erewrite sum_finite_equiv. Focus 2. intros.
rewrite (SRmul_comm LPRsrt). reflexivity.
rewrite sum_finite_scales.
rewrite (sum_finite_fin_equiv _ _ finiteFN).
rewrite H. ring.
Qed.

End OneTimePad.