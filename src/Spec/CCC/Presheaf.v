(* Category of presheaves over a given category *)

Set Universe Polymorphism.
Set Asymmetric Patterns.

Module Presheaf.


Require Import Types.Setoid Prob.Spec.Category.
Import Category.

Local Open Scope obj.
Local Open Scope morph.

Section Presheaf.

Universe Univ.

Context {U : Type@{Univ}} {ccat : CCat U} {cmc : CMC U}.

(** The notion of a setoid *must* depend on the category U.
    The setoid should live in 1 larger than the universe of 
    U. *)

Require Import Morphisms.

Record PSh := 
  { psh_obj :> U -> Setoid@{Univ}
  ; psh_morph : forall {Γ Δ} (ext : Δ ~~> Γ), psh_obj Γ -> psh_obj Δ
  ; psh_morph_Proper :
     forall Γ Δ, Proper (eq ==> seq _ ==> seq _) (@psh_morph Γ Δ)
  ; psh_morph_id : forall A (x : psh_obj A),
    seq (psh_obj A) (psh_morph id x) x
  ; psh_morph_compose : forall A B C (g : C ~~> B) (f : B ~~> A) (x : psh_obj A),
   seq (psh_obj C) (psh_morph g (psh_morph f x))
       (psh_morph (f ∘ g) x)
  }.

Record CFunc {A B : PSh} {Γ : U} : Type :=
  { Func_eval :> forall Δ, Δ ~~> Γ -> A Δ -> B Δ
  ; Func_Proper : forall Δ, Proper (eq ==> seq (A Δ) ==> seq (B Δ)) (Func_eval Δ)
  ; Func_ok : forall Δ (ext : Δ ~~> Γ) Δ' (ext' : Δ' ~~> Δ) (x x' : A Δ),
     seq (psh_obj A Δ) x x'
   -> seq (psh_obj B Δ')
       (psh_morph B ext' (Func_eval Δ ext x))
       (Func_eval Δ' (ext ∘ ext') (psh_morph A ext' x'))
  }.

Record NatTrns (A B : PSh) :=
  { nattrns :> forall Γ : U, A Γ -> B Γ
  ; nattrns_Proper : forall Γ, Proper (seq _ ==> seq _) (nattrns Γ)
  ; nattrns_ok : forall Γ Δ (ext : Δ ~~> Γ) (x x' : A Γ),
     seq (psh_obj A Γ) x x' ->
     seq (psh_obj B Δ) 
        (psh_morph B ext (nattrns Γ x))
        (nattrns Δ (psh_morph A ext x'))
  }.


Arguments CFunc : clear implicits.

Require Import Morphisms.
Definition func_Setoid (A B : PSh)
 (Γ : U) : Setoid.
Proof. refine (
  {| sty := CFunc A B Γ
   ; seq := fun f f' => forall Δ ext ext' e e', ext == ext' 
      -> seq (A Δ) e e' -> seq (B Δ) (f Δ ext e) (f' Δ ext' e')
  |}).
constructor; unfold Reflexive, Symmetric, Transitive;
  intros.
- apply x; assumption.
- symmetry. eapply H; symmetry; eassumption.
- etransitivity. apply H; eassumption.
  apply H0; reflexivity.
Defined.

Context {cmcprops : CMC_Props U }.

Definition CFunc_morph {A B} {Γ Δ} (ext : Δ ~~> Γ) 
  (f : CFunc A B Γ) : (CFunc A B Δ).
Proof.
refine (
  {| Func_eval := fun G ext' x => f _ (ext ∘ ext') x |}).
- intros. unfold Proper, respectful.
  intros. apply Func_Proper. rewrite H. reflexivity.
  assumption.
- intros. rewrite Func_ok.
  apply Func_Proper. symmetry. apply compose_assoc. 
  apply psh_morph_Proper. reflexivity. eassumption. reflexivity.
Defined.

Definition func_PSh (A B : PSh) : PSh.
Proof.
refine ( 
 {| psh_obj := func_Setoid A B
  ; psh_morph := fun _ _ => CFunc_morph
 |}).
- intros. unfold Proper, respectful.
  simpl. intros.
  rewrite Func_Proper.
  apply H0. reflexivity. eassumption. rewrite H, H1. reflexivity.
  reflexivity.
- simpl. intros. apply Func_Proper.
  rewrite H.
  apply compose_id_left. assumption.
- simpl. intros. apply Func_Proper.
  rewrite H.
  apply compose_assoc. assumption.
Defined.

Definition prod_PSh (A B : PSh) : PSh.
Proof.
refine (
  {| psh_obj := fun Γ => prod_Setoid (A Γ) (B Γ)
  ;  psh_morph := fun Γ Δ f p => let (x, y) := p in 
      (psh_morph _ f x, psh_morph _ f y)
  |} ).
- intros. 
  unfold Proper, respectful. intros.
  destruct x0, y0, H0.
  simpl in *. split; apply psh_morph_Proper; assumption.
- simpl. intros. destruct x. simpl.
  split; apply psh_morph_id.
- simpl. intros. destruct x. simpl. 
  split; apply psh_morph_compose.
Defined.

(** Yoneda embedding *)
Definition Y (X : U) : PSh.
Proof.
refine (
  {| psh_obj := fun Γ => Hom_Setoid (cmc := cmc) Γ X
   ; psh_morph := fun Γ Δ f x => x ∘ f
  |}
).
- intros. unfold Proper, respectful.
  simpl. intros. apply compose_Proper; assumption.
- simpl. intros. apply compose_id_right.
- simpl. intros. rewrite compose_assoc.
  reflexivity.
Defined.

(** Constant presheaf for setoids *)
Definition KStd (A : Setoid) : PSh.
Proof.
unshelve eapply (
  {| psh_obj := fun _ => A
   ; psh_morph := fun _ _ _ x => x
  |}).
- prove_map_Proper. assumption.
- simpl. intros. reflexivity.
- simpl. intros. reflexivity.
Defined.

Definition K (A : Type) : PSh := KStd (Leibniz A).

Definition id_PSh {A : PSh} : NatTrns A A.
Proof.
refine (
  {| nattrns := fun Γ x => x |}).
- unfold Proper, respectful. intros. auto.
- intros. simpl. apply psh_morph_Proper.
  reflexivity. assumption.
Defined.

Definition compose_PSh {A B C : PSh}
  (g : NatTrns B C) (f : NatTrns A B) : NatTrns A C.
Proof.
refine (
  {| nattrns := fun Γ x => g Γ (f Γ x) |}
).
- unfold Proper, respectful. intros.
  repeat apply nattrns_Proper. assumption.
- intros. rewrite (nattrns_ok _ _ g). 
  apply nattrns_Proper.
  rewrite (nattrns_ok _ _ f).
  apply nattrns_Proper. apply psh_morph_Proper.
  reflexivity. eassumption. symmetry. eassumption.
  apply nattrns_Proper. assumption.
Defined.

Definition unit_PSh : PSh.
Proof.
refine (
  {| psh_obj := fun _ => unit_Setoid
   ; psh_morph := fun _ _ _ x => x
  |}).
- unfold Proper, respectful. intros.
  simpl. auto.
- simpl. intros. auto.
- simpl. intros. auto.
Defined.

Definition tt_PSh {A : PSh} : NatTrns A unit_PSh.
Proof.
apply ( Build_NatTrns A unit_PSh
    (fun _ _ => Datatypes.tt)).
- intros. unfold Proper, respectful.
  intros. reflexivity.
- intros. constructor.
Defined.

Definition pair_PSh {X A B} (f : NatTrns X A)
  (g : NatTrns X B) : NatTrns X (prod_PSh A B).
Proof.
apply (Build_NatTrns _ (prod_PSh A B)
  (fun Γ (x : X Γ) => (f Γ x, g Γ x))).
- intros. unfold Proper, respectful.
  intros. simpl. split; apply nattrns_Proper; assumption.
- intros. simpl. split; apply nattrns_ok; assumption.
Defined.

Definition fst_Psh {A B} : NatTrns (prod_PSh A B) A.
Proof.
apply (Build_NatTrns (prod_PSh A B) A
  (fun Γ p => let (x, _) := p in x)).
- intros. unfold Proper, respectful.
  intros. destruct x, y, H. simpl in *. assumption.
- intros. destruct x, x', H.
  simpl in *. apply psh_morph_Proper. reflexivity.
  assumption.
Defined.

Definition snd_Psh {A B} : NatTrns (prod_PSh A B) B.
Proof.
apply (Build_NatTrns (prod_PSh A B) B
  (fun Γ p => let (_, y) := p in y)).
- intros. unfold Proper, respectful.
  intros. destruct x, y, H. simpl in *. assumption.
- intros. destruct x, x', H.
  simpl in *. apply psh_morph_Proper. reflexivity.
  assumption.
Defined.

Definition eq_map (A B : PSh) (f g : NatTrns A B) :=
  forall Γ (x x' : A Γ),
     seq (psh_obj A Γ) x x' ->
     seq (psh_obj B Γ) (f Γ x) (g Γ x').

Instance eq_Equivalence_PSh A B : Equivalence (eq_map A B).
Proof.
constructor; unfold eq_map, Reflexive, Symmetric, Transitive; intros.
- apply nattrns_Proper. assumption.
- symmetry. apply H. symmetry. assumption.
- etransitivity. apply H. eassumption.
  apply H0. reflexivity.
Qed.

Definition eval_PSh_trns {A B : PSh} :
  forall Γ, (prod_PSh (func_PSh A B) A) Γ -> B Γ.
Proof.
simpl. intros. destruct X.
exact (c Γ id s).
Defined.

Definition eval_PSh {A B : PSh} : NatTrns (prod_PSh (func_PSh A B) A) B.
Proof.
constructor 1 with eval_PSh_trns.
- intros. unfold Proper, respectful. simpl. intros.
  destruct x, y, H. simpl in *. apply H. 
  reflexivity. assumption. 
- simpl. intros. destruct x, x', H. simpl in *.
  etransitivity. Focus 2.
  apply H. reflexivity. apply psh_morph_Proper.
  reflexivity. eassumption.
  etransitivity. apply Func_ok. eassumption.
  apply Func_Proper.
  rewrite compose_id_left, compose_id_right.
  reflexivity. apply psh_morph_Proper. reflexivity.
  symmetry. assumption.
Defined.

Definition abstract_PSh_trns {X A B : PSh}
 (f : NatTrns (prod_PSh X A) B)
 (Γ : U) (x : X Γ) : 
 forall Δ, Δ ~~> Γ -> A Δ -> B Δ.
Proof.
intros. apply f. simpl. split.
eapply psh_morph; eassumption. assumption.
Defined.

Definition abstract_PSh_CFunc {X A B : PSh}
 (f : NatTrns (prod_PSh X A) B)
 (Γ : U) (x : X Γ) : (func_PSh A B) Γ.
Proof.
simpl. refine (
  {| Func_eval := abstract_PSh_trns f Γ x |}).
- intros. unfold Proper, respectful.
  unfold abstract_PSh_trns.
  intros.  apply nattrns_Proper. simpl.
  split. apply psh_morph_Proper. assumption.
  reflexivity. assumption.
- simpl. intros. unfold abstract_PSh_trns.
  etransitivity.  Focus 2.
  apply nattrns_Proper.
 simpl.
  instantiate (1 := psh_morph (prod_PSh X A) ext'
   (psh_morph X ext x, x')).
  simpl. split. apply psh_morph_compose. reflexivity.
 apply nattrns_ok. simpl. split. 
  apply psh_morph_Proper; reflexivity. assumption.
Defined.

Definition abstract_PSh {X A B : PSh} 
  (f : NatTrns (prod_PSh X A) B) : NatTrns X (func_PSh A B).
Proof.
apply (Build_NatTrns X (func_PSh A B) (abstract_PSh_CFunc f)).
- intros. unfold Proper, respectful. simpl.
  unfold abstract_PSh_trns. intros.
  apply nattrns_Proper. simpl. split.
  apply psh_morph_Proper; assumption. assumption.
- simpl. unfold abstract_PSh_trns. intros.
  apply nattrns_Proper. simpl. split.
  etransitivity. apply psh_morph_Proper.
  rewrite H0.  reflexivity. eassumption.
  symmetry. apply psh_morph_compose. assumption.
Defined.

Require CMorphisms.

(** The following two typeclass instances loop,
    so be very careful about adding them to the
    typeclass database *)
Local Instance CCat_PSh : CCat PSh :=
  {| arrow := NatTrns
   ; prod := prod_PSh
   ; eq := eq_map
  |}.

Local Instance CMC_Psh : CMC PSh :=
  {| id := fun _ => id_PSh
  ; compose := fun _ _ _ => compose_PSh
  ; unit := unit_PSh
  ; tt := fun _ => tt_PSh
  ; fst := fun _ _ => fst_Psh
  ; snd := fun _ _ => snd_Psh
  ; pair := fun _ _ _ => pair_PSh
  ; eq_Equivalence := eq_Equivalence_PSh |}.
Proof.
- simpl. unfold eq_map. intros.
  simpl. auto.
- simpl. unfold eq_map. intros. simpl.
  split; auto.
Defined.

Require Import Prob.Spec.CCC.CCC.
Import CCC.

Instance CCCOps_PSh : @CCCOps PSh CCat_PSh :=
  {| Func := func_PSh
  ; eval := fun _ _ => eval_PSh
  ; abstract := fun _ _ _ => abstract_PSh
  |}.


Instance CMCProps_PSh : CMC_Props PSh.
Proof.
constructor; simpl; unfold eq_map; simpl; intros.
- apply nattrns_Proper. assumption.
- apply nattrns_Proper. assumption.
- repeat apply nattrns_Proper. assumption.
- pose proof (nattrns_Proper _ _ h).
  unfold Proper, respectful in H0.
  specialize (H0 Γ x x' H). destruct H0.
  split; assumption.
- apply nattrns_Proper. assumption.
- apply nattrns_Proper. assumption.
- auto.
Qed.

Instance CCCProps_PSh : CCCProps PSh (cccops := CCCOps_PSh).
Proof.
constructor.
- intros. unfold Proper, respectful.
  simpl. unfold eq_map. simpl. intros.
  apply H. simpl. split. apply psh_morph_Proper; assumption.
  assumption.
- simpl. unfold eq_map. simpl. intros.
  destruct x, x', H. unfold abstract_PSh_trns. simpl in *.
  apply nattrns_Proper. simpl. split.
  rewrite psh_morph_id. assumption.
  assumption.
- simpl. unfold eq_map. simpl. intros.
  pose proof (nattrns_ok _ _ f) as Hf.
  simpl in Hf. rewrite <- Hf.
  Focus 2. symmetry; eassumption.
  Focus 3. symmetry; eassumption.
  2 : reflexivity.
  pose proof (nattrns_Proper _ _ f) as H2.
  unfold Proper, respectful in H2. simpl in H2.
  rewrite H2. reflexivity. reflexivity. 
  rewrite H0, compose_id_right. reflexivity.
  reflexivity.
- intros. simpl. unfold eq_map. simpl. intros.
  unfold abstract_PSh_trns. simpl. apply (nattrns_Proper _ _ e).
  simpl. split. rewrite (nattrns_ok _ _ f).
  apply (nattrns_Proper _ _ f). apply psh_morph_Proper. 
  assumption. reflexivity. assumption. assumption.
Qed.

Ltac build_CFunc := match goal with
 | [  |- CFunc ?A ?B ?Γ ] => 
    simple refine (Build_CFunc A B Γ _ _ _)
 end.

Definition toConst {A : PSh} (x : A unit)
  : Const A.
Proof.
simpl. simple refine (Build_NatTrns _ _ _ _ _).
- intros. eapply psh_morph. 2: eassumption.
  apply tt.
- unfold Proper, respectful. intros. apply psh_morph_Proper;
  reflexivity.
- simpl. intros. rewrite psh_morph_compose.
  apply psh_morph_Proper. apply unit_uniq.
  reflexivity.
Defined.

Definition Y_Prod1 {A B : U} : 
  Y A * Y B ~~> Y (A * B).
Proof.
simple refine (Build_NatTrns _ _ _ _ _).
+ simpl. intros. destruct X. apply pair; assumption.
+ simpl. unfold Proper, respectful. intros.
  destruct x, y, H. simpl in *. apply pair_Proper; assumption.
+ simpl. intros.
  destruct x, x', H. simpl in *.
  rewrite <- pair_f. apply compose_Proper.
  apply pair_Proper; assumption. reflexivity.
Defined.

Definition Y_Prod2 {A B} : Y (A * B) ~~> Y A * Y B.
Proof.
simple refine (Build_NatTrns _ _ _ _ _).
+ simpl. intros. split. exact (fst ∘ X).
  exact (snd ∘ X).
+ simpl. intros. unfold Proper, respectful.
  intros. simpl. split; rewrite H; reflexivity.
+ simpl. intros. split; rewrite H, compose_assoc; reflexivity.
Defined.

Lemma Y_Prod_Iso A B : Iso (Y A * Y B) (Y (A * B)).
Proof.
refine (
  {| to := Y_Prod1
   ; from := Y_Prod2
  |})
  ; simpl; unfold eq_map; simpl; intros.
- rewrite <- pair_f. rewrite pair_id. 
  rewrite compose_id_left. assumption.
- destruct x, x', H. simpl in *. split.
  + rewrite pair_fst. assumption.
  + rewrite pair_snd. assumption.
Qed.

Definition Y_Func1 {A B} Γ : (Y A ==> B) Γ -> B (Γ * A).
Proof.
simpl. intros. eapply psh_morph. Focus 2.
apply X. eapply fst. simpl. apply snd. apply id.
Defined.

Definition Y_Func2 {A} {B : PSh} Γ : B (Γ * A) -> (Y A ==> B) Γ.
Proof.
simpl. intros. build_CFunc.
- simpl. intros. eapply psh_morph. 2: eassumption.
  apply pair; assumption.
- simpl. unfold Proper, respectful. intros.
  apply psh_morph_Proper. apply pair_Proper; assumption.
  reflexivity.
- simpl. intros. rewrite psh_morph_compose.
  apply psh_morph_Proper. rewrite <- pair_f. rewrite H.
  reflexivity. reflexivity.
Defined.

Definition apply {A B : PSh} Γ : (A ==> B) Γ -> A Γ -> B Γ.
Proof.
simpl. intros. apply X. apply id. assumption.
Defined.

Inductive Basic : U -> PSh -> Type :=
  | Basic_Base : forall A : U, Basic A (Y A)
  | Basic_Prod : forall a A b B, Basic a A -> Basic b B -> 
      Basic (a * b) (A * B).

Lemma Y_Basic_Iso {a A} (b : Basic a A) : Iso (Y a) A.
Proof.
induction b.
- apply Iso_Refl.
- eapply Iso_Trans. eapply Iso_Sym. apply Y_Prod_Iso.
  apply Iso_Prod; assumption.
Defined.

Definition Y_ctxt (Δ A : U) : PSh.
Proof.
refine (
  {| psh_obj := fun Γ => Hom_Setoid (cmc := cmc) (Γ * Δ) A
   ; psh_morph := fun Γ Γ' (ext : Γ' ~~> Γ) (f : Γ * Δ ~~> A) =>
      f ∘ (ext ⊗ id)
  |}).
- intros. unfold Proper, respectful.
  simpl. intros.
  rewrite H, H0. reflexivity.
- simpl. intros. unfold parallel.
  rewrite !compose_id_left.
  rewrite <- (compose_id_right fst).
  rewrite <- (compose_id_right snd).
  rewrite <- pair_uniq. apply compose_id_right.
- simpl. intros. rewrite <- !compose_assoc. 
  apply compose_Proper. reflexivity.
  unfold parallel. rewrite pair_f. apply pair_Proper.
  rewrite <- !compose_assoc. apply compose_Proper.
  reflexivity. rewrite pair_fst.  reflexivity.
  rewrite <- !compose_assoc. apply compose_Proper.
  reflexivity. rewrite pair_snd. apply compose_id_left.
Defined.


Lemma extract_Basic {Γ} {a A} (b : Basic a A)
  : A Γ -> Γ ~~> a.
Proof.
intros. apply (nattrns _ _ (from (Y_Basic_Iso b))). assumption.
Defined.

Lemma unextract_Basic {Γ a A} (b : Basic a A)
  : (Γ ~~> a) -> A Γ.
Proof.
intros. apply (nattrns _ _ (to (Y_Basic_Iso b))). assumption.
Defined.

Inductive FirstOrder : U -> U -> PSh -> Type :=
  | FO_Basic : forall {a A}, Basic a A -> FirstOrder unit a A
  | FO_Func : forall {arg args ret A B}, 
     Basic arg A -> FirstOrder args ret  B 
    -> FirstOrder (arg * args) ret (A ==> B).

Lemma basic_arg Γ {a A} (b : Basic a A)
  : A (Γ * a).
Proof.
eapply unextract_Basic. eassumption.
apply snd.
Defined.

Lemma Y_ctxt1 {A B : U} : 
  Y A ==> Y B ~~> Y_ctxt A B.
Proof. simpl.
simple refine (Build_NatTrns _ _ _ _ _).
- simpl. intros.
  apply X. apply fst.  simpl. apply snd.
- intros. unfold Proper, respectful.
  simpl. intros.
  apply H; reflexivity.
- simpl. intros. 
  pose proof (Func_ok x) as H'. simpl in H'.
  rewrite H'. rewrite H. apply (Func_Proper x').
  reflexivity. reflexivity.
  apply parallel_fst. 2 :reflexivity.
  rewrite parallel_snd.
  apply compose_id_left.
Defined.

Lemma Y_ctxt2 {A B : U} :
  Y_ctxt A B ~~> Y A ==> Y B.
Proof.
simpl. simple refine (Build_NatTrns _ _ _ _ _).
- simpl. intros.
  build_CFunc. 
  + simpl. intros. 
    refine (compose X _). apply pair; assumption.
  + unfold Proper, respectful. simpl. intros.
    rewrite H, H0; reflexivity.
  + simpl. intros. rewrite H.
    rewrite <- pair_f. rewrite compose_assoc.
    reflexivity.
- unfold Proper, respectful. simpl. intros.
  rewrite H, H0, H1; reflexivity.
- simpl. intros. rewrite H, H0, H1.
  rewrite <- !compose_assoc.
  rewrite parallel_pair. rewrite compose_id_left.
  reflexivity.
Defined.

Lemma Y_ctxt_Iso (A B : U) : Y_ctxt A B ≅ Y A ==> Y B.
Proof.
refine (
  {| to := Y_ctxt2
   ; from := Y_ctxt1
  |}); simpl; unfold eq_map; simpl; intros.
rewrite H. 2:reflexivity.
pose proof (Func_ok x') as Hf. simpl in Hf.
rewrite Hf. 2: reflexivity.
apply (Func_Proper x'). rewrite pair_fst. assumption.
simpl. rewrite pair_snd. assumption. reflexivity.
rewrite pair_id. rewrite compose_id_right.
assumption.
Defined.

Lemma Y_Y_ctxt1 {A : U} : Y A ~~> Y_ctxt unit A.
Proof.
simple refine (Build_NatTrns _ _ _ _ _).
- simpl. intros. refine (_ ∘ fst). assumption.
- simpl. intros. unfold Proper, respectful.
  intros. rewrite H; reflexivity.
- simpl.  intros. 
  rewrite <- !compose_assoc.
  rewrite parallel_fst. rewrite H.
  reflexivity.
Defined.

Lemma Y_Y_ctxt2 {A : U} : Y_ctxt unit A ~~> Y A.
Proof.
simple refine (Build_NatTrns _ _ _ _ _).
- simpl. intros.
  refine (_ ∘ ⟨ id , tt ⟩). assumption.
- unfold Proper, respectful. simpl. intros.
  rewrite H; reflexivity.
- simpl. intros. 
  rewrite H. rewrite <- !compose_assoc. 
  rewrite parallel_pair.
  rewrite pair_f. rewrite !compose_id_left, !compose_id_right.
  rewrite unit_uniq. reflexivity.
Defined.

Lemma Y_Y_ctxt_Iso {A : U} : Y A ≅ Y_ctxt unit A.
Proof.
refine (
  {| to := Y_Y_ctxt1
  ; from := Y_Y_ctxt2
  |}); simpl; unfold eq_map; simpl; intros.
rewrite <- compose_assoc. rewrite pair_f.
rewrite (unit_uniq _ snd).
rewrite compose_id_left. rewrite pair_id.
rewrite compose_id_right. assumption.
rewrite <- compose_assoc. rewrite pair_fst.
rewrite compose_id_right. assumption.
Defined.

Lemma Func_Iso {A A' B B'} (a : A ≅ A')
  (b : B ≅ B') : A ==> B ≅ A' ==> B'.
Proof.
refine (
  {| to := precompose (to b) ∘ postcompose (from a)
   ; from := postcompose (to a) ∘ precompose (from b)
  |}).
- simpl. unfold eq_map. simpl.
intros. 
pose proof (to_from b) as Htf.
simpl in Htf. unfold eq_map in Htf. simpl in Htf.
rewrite Htf.  apply H. eassumption. eassumption.
apply Func_Proper. rewrite !compose_id_right. reflexivity.
clear Htf. pose proof (to_from a) as Htf. simpl in Htf. 
unfold eq_map in H1. simpl in Htf. apply Htf. reflexivity.
- simpl. unfold eq_map. simpl.
intros. 
pose proof (from_to b) as Htf.
simpl in Htf. unfold eq_map in Htf. simpl in Htf.
rewrite Htf.  apply H. eassumption. eassumption.
apply Func_Proper. rewrite !compose_id_right. reflexivity.
clear Htf. pose proof (from_to a) as Htf. simpl in Htf. 
unfold eq_map in H1. simpl in Htf. apply Htf. reflexivity.
Defined.

Lemma FirstOrder_Iso {args ret A}
  (fo : FirstOrder args ret A) :
  A ≅ Y_ctxt args ret.
Proof.
induction fo.
- eapply Iso_Trans. apply (Iso_Sym (Y_Basic_Iso b)).
  apply (Y_Y_ctxt_Iso).
- eapply Iso_Trans.
  Focus 2. apply (Iso_Sym (Y_ctxt_Iso _ _)).
  eapply Iso_Trans.
  Focus 2. eapply Func_Iso.
  apply Y_Prod_Iso. apply Iso_Refl.
  eapply Iso_Trans.
  Focus 2. apply Curry_Iso.
  apply Func_Iso. apply Iso_Sym. apply Y_Basic_Iso.
  assumption. eapply Iso_Trans. eassumption.
  apply Y_ctxt_Iso.
Defined.

Definition extract_FirstOrder {args ret A} 
  (fo : FirstOrder args ret A) :
  A ~~> Y_ctxt args ret := to (FirstOrder_Iso fo).

Definition unextract_FirstOrder {args ret A}
  (fo : FirstOrder args ret A) :
  Y_ctxt args ret ~~> A
  := from (FirstOrder_Iso fo).

Lemma extract_basic_fully_abstract {Γ} {a A} (b : Basic a A)
  (e e' : A Γ)
  : seq (A Γ) e e'
  -> (extract_Basic b e == extract_Basic b e')%morph.
Proof.
intros. unfold extract_Basic.
apply (nattrns_Proper _ _ (from (Y_Basic_Iso b))).
assumption.
Qed.

Lemma extract_FO_fully_abstract {Γ} {args ret A}
  (fo : FirstOrder args ret A)
  (e e' : A Γ)
  : seq (A Γ) e e'
  -> (extract_FirstOrder fo Γ e == extract_FirstOrder fo Γ e')%morph.
Proof.
intros. 
unfold extract_FirstOrder. 
apply (nattrns_Proper _ _ (to (FirstOrder_Iso fo))).
assumption.
Qed.

Lemma Yoneda_extended {arg ret} :
  (Hom_Setoid (unit * arg) ret ≅ Hom_Setoid unit (Y_ctxt arg ret))%setoid.
Proof.
simple refine (Setoid.Build_Iso _ _ _ _ _ _ _ _).
- intros. apply toConst. simpl. apply X.
- simpl. intros. apply X. simpl. constructor.
- unfold Proper, respectful. simpl. intros.
  unfold eq_map. simpl. intros. 
  rewrite H; reflexivity.
- unfold Proper, respectful. simpl. unfold eq_map. simpl.
  intros. apply H. constructor.
- simpl. unfold eq_map. intros.
  simpl. apply (nattrns_ok _ _ a). simpl. constructor.
- simpl. intros. unfold parallel.
  rewrite <- (compose_id_right b) at 2.
  rewrite <- pair_id.
  rewrite (unit_uniq _ fst).
  rewrite compose_id_left. reflexivity.
Defined.

Lemma presheaf_connection {arg ret A}
  (fo : FirstOrder arg ret A)
  : (Hom_Setoid arg ret ≅ Hom_Setoid unit A)%setoid.
Proof.
eapply Setoid.Iso_Trans.
Focus 2. eapply Hom_Setoid_Iso. apply Iso_Refl. 
eapply Iso_Sym. apply (FirstOrder_Iso fo).
eapply Setoid.Iso_Trans.
eapply  Hom_Setoid_Iso.
eapply Iso_Sym. apply Iso_add_unit_left.
apply Iso_Refl. apply Yoneda_extended.
Defined.

Definition to_presheaf {arg ret A} (fo : FirstOrder arg ret A)
  : arg ~~> ret -> Const A
  := Setoid.to (presheaf_connection fo).

Definition from_presheaf {arg ret A} (fo : FirstOrder arg ret A)
  : Const A -> arg ~~> ret
  := Setoid.from (presheaf_connection fo).

Definition pt_to_presheaf {A : U} : 
  unit ~~> A -> Const (Y A).
Proof.
intros. apply toConst. simpl. assumption.
Defined.

Definition pt_from_presheaf {A : U}
  : Const (Y A) -> unit ~~> A.
Proof.
intros. apply X. constructor.
Defined.

End Presheaf.

Arguments PSh U {_ _}.

End Presheaf.