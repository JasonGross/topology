Set Universe Polymorphism. 

(** I will try to use the same names for the operations
    that there are in Coq *)
Require Import RelationClasses Morphisms.
Module Category.

(** A category, with its type of morphisms, and a product operation *)
Class CCat {U : Type} : Type := 
  { arrow : U -> U -> Type
  ; prod : U -> U -> U
  ; eq : forall {A B}, arrow A B -> arrow A B -> Prop
  }.

Arguments CCat : clear implicits.

(** Notation for objects of categories *)
Delimit Scope obj_scope with obj.
Local Open Scope obj.
Infix "~~>" := arrow (at level 75) : obj_scope.
Infix "*" := prod : obj_scope.

Delimit Scope morph_scope with morph.
Local Open Scope morph.
Infix "==" := eq (at level 70, no associativity) : morph_scope.

Ltac prove_map_Proper := unfold Proper, respectful; intros;
  repeat match goal with
  | [ H : (_ == _)%morph |- (_ == _)%morph ] => rewrite H; clear H
  end; try reflexivity.

(** Cartesian monoidal categories *)

Class CMC {U : Type} {ccat : CCat U} : Type :=
  { id : forall {A}, A ~~> A
  ; compose : forall {A B C}, B ~~> C -> A ~~> B -> A ~~> C
 
  ; unit : U
  ; tt : forall {Γ}, Γ ~~> unit

  ; fst : forall {A B}, A * B ~~> A
  ; snd : forall {A B}, A * B ~~> B

  ; pair : forall {Γ A B}, (Γ ~~> A) -> (Γ ~~> B) -> (Γ ~~> A * B)

  ; eq_Equivalence :> forall A B, Equivalence (eq (A := A) (B := B))
  ; compose_proper : forall {A B C} (f f' : A ~~> B) (g g' : B ~~> C),
      f == f' -> g == g' -> compose g f == compose g' f'
  ; pair_proper : forall {Γ A B} (f f' : Γ ~~> A) (g g' : Γ ~~> B),
      f == f' -> g == g' -> pair f g == pair f' g'
  }.

Infix "∘" := compose (at level 40, left associativity) : morph_scope.
Notation "⟨ f , g ⟩" := (pair f g) : morph_scope.

Definition parallel {U} `{CMC U} {A B C D : U} (f : A ~~> B) (g : C ~~> D) : A * C ~~> B * D :=
  ⟨ f ∘ fst , g ∘ snd ⟩.

Infix "⊗" := parallel (at level 25) : morph_scope.


Require Coq.Setoids.Setoid.
Global Instance compose_Proper `{CMC} : forall A B C : U,
  Proper (eq (A := B) (B := C) ==> eq ==> eq (A := A)) compose.
Proof. 
intros. unfold Proper, respectful.
intros. apply compose_proper; assumption.
Qed.

Global Instance pair_Proper `{CMC} : forall A B C : U,
  Proper (eq (A := A) (B := B) ==> eq (A := A) (B := C) ==> eq) pair.
Proof. 
intros. unfold Proper, respectful.
intros. apply pair_proper; assumption.
Qed.

Theorem parallel_proper `{CMC} : forall {A B C D} (f f' : A ~~> B) (g g' : C ~~> D),
    f == f' -> g == g' -> parallel f g == parallel f' g'.
Proof. intros A B C D f f' g g' ff' gg'.
 unfold parallel. rewrite ff', gg'. reflexivity.
Qed.

Definition diagonal {U} `{CMC U} {A : U} : A ~~> A * A := ⟨ id , id ⟩.
Definition swap {U} `{CMC U} {A B : U} : A * B ~~> B * A := ⟨snd, fst⟩.

Global Instance parallel_Proper `{CMC} : forall A B C D : U,
  Proper (eq (A := A) (B := B) ==> eq (A := C) (B := D) ==> eq) parallel.
Proof. 
intros. unfold Proper, respectful.
intros. apply parallel_proper; assumption.
Qed.

Arguments CMC U {_}.


Definition Mono {U} `{CMC U} {A B : U} (f : A ~~> B) :=
  forall X (g1 g2 : X ~~> A), f ∘ g1 == f ∘ g2 -> g1 == g2.

Definition Epi {U} `{CMC U} {A B : U} (f : B ~~> A) :=
  forall X (g1 g2 : A ~~> X), g1 ∘ f == g2 ∘ f -> g1 == g2.

Record Iso {U} `{CMC U} {A B : U} : Type :=
  { to   : A ~~> B
  ; from : B ~~> A
  ; to_from : to ∘ from == id
  ; from_to : from ∘ to == id
  }.

Arguments Iso {_ _ _} A B.

Infix "≅" := Iso (at level 70, no associativity) : obj_scope.

Section BasicOps. 
Context {U} `{CMC U}.

Definition ap0 {Γ A : U} (f : unit ~~> A)
  : Γ ~~> A := f ∘ tt.

Definition ap1 {Γ A B : U} (f : A ~~> B) (x : Γ ~~> A)
  : Γ ~~> B := f ∘ x.

Definition ap2 {Γ A B C : U} 
  (f : A * B ~~> C) (x : Γ ~~> A) (y : Γ ~~> B) : Γ ~~> C := 
  f ∘ ⟨x, y⟩.

Definition ap3 {Γ A B C D : U} 
  (f : A * B * C ~~> D) (x : Γ ~~> A) (y : Γ ~~> B) (z : Γ ~~> C) : Γ ~~> D := 
  f ∘ ⟨⟨x, y⟩, z⟩.


Definition add_unit_left {A : U} : A ~~> unit * A
  := ⟨tt, id⟩.

Definition add_unit_right {A : U} : A ~~> A * unit
  := ⟨id, tt⟩.

End BasicOps.

Class CMC_Props {U : Type} {ccat : CCat U} {cmc : CMC U} : Prop :=
  { compose_id_left : forall {A B} (f : A ~~> B), id ∘ f == f
  ; compose_id_right : forall {A B} (f : A ~~> B), f ∘ id == f
  ; compose_assoc : forall {A B C D} (f : A ~~> B) (g : B ~~> C) (h : C ~~> D), h ∘ (g ∘ f) == (h ∘ g) ∘ f
  ; pair_uniq : forall {A B C} (h : A ~~> B * C), h == ⟨fst ∘ h, snd ∘ h⟩
  ; pair_fst : forall {A B C} (f : A ~~> B) (g : A ~~> C), fst ∘ ⟨f, g⟩ == f
  ; pair_snd : forall {A B C} (f : A ~~> B) (g : A ~~> C), snd ∘ ⟨f, g⟩ == g
  ; unit_uniq : forall {A} (h k : A ~~> unit), h == k
  }.

Arguments CMC_Props U {_ _}.

Ltac remove_eq_left :=
  repeat rewrite <- compose_assoc; repeat (apply compose_Proper; try reflexivity).
Ltac remove_eq_right :=
  repeat rewrite compose_assoc; repeat (apply compose_Proper; try reflexivity).


Section BasicProps.
  Require Coq.Setoids.Setoid.
  Context {U} {ccat : CCat U} {cmc : CMC U} {cmp : @CMC_Props U ccat cmc}.  

  Theorem proj_eq : forall {A B C : U} {f f' : A ~~> B * C},
      (fst ∘ f) == (fst ∘ f') -> (snd ∘ f == snd ∘ f') -> f == f'.
  Proof. intros A B C f f' Hfst Hsnd. rewrite (pair_uniq f). rewrite (pair_uniq f').
         rewrite Hfst, Hsnd. reflexivity.
  Defined.
  

  Theorem unit_isom_left : forall {A : U}, (unit * A) ≅ A.
  Proof. intros A. refine (@Build_Iso U ccat cmc (unit * A) A snd ⟨tt, id⟩ _ _).
         - rewrite pair_snd. reflexivity.
         - apply proj_eq.
           + apply unit_uniq.
           + rewrite compose_id_right. rewrite compose_assoc. rewrite pair_snd. rewrite compose_id_left.
             reflexivity.
  Defined.

  Theorem unit_isom_right : forall {A : U}, (A * unit) ≅ A.
  Proof. intros A. refine (@Build_Iso U ccat cmc (A * unit) A fst ⟨id, tt⟩ _ _).
         - rewrite pair_fst. reflexivity.
         - apply proj_eq.
           + rewrite compose_id_right. rewrite compose_assoc. rewrite pair_fst. rewrite compose_id_left.
             reflexivity.
           + apply unit_uniq.            
  Defined.

  Lemma pair_id {A B : U} :
    ⟨ fst, snd ⟩ == id (A := A * B).
  Proof.
  rewrite (pair_uniq id).
  rewrite !compose_id_right. reflexivity.
  Qed.

  
  Lemma parallel_pair : forall {A B C D E : U} (f : A ~~> B) (g : A ~~> C) (h : B ~~> D) (k : C ~~> E), (h ⊗ k) ∘ ⟨f, g⟩ == ⟨h ∘ f, k ∘ g⟩.
  Proof. intros A B C D E f g h k.
         unfold parallel. apply proj_eq.
         - rewrite compose_assoc. rewrite pair_fst, pair_fst.
           rewrite <- compose_assoc. rewrite pair_fst. reflexivity.
         - rewrite compose_assoc. rewrite pair_snd, pair_snd.
           rewrite <- compose_assoc. rewrite pair_snd. reflexivity.
  Defined.
  
    
  Lemma parallel_fst : forall {A B C D : U} (f : A ~~> B) (g : C ~~> D),
      fst ∘ (f ⊗ g) == f ∘ fst. (* Have I already proven this somewhere else maybe? *)
  Proof. intros A B C D f g.
         unfold parallel.
         rewrite pair_fst.
         reflexivity.
  Qed.
  
  Lemma parallel_snd : forall {A B C D : U} (f : A ~~> B) (g : C ~~> D),
      snd ∘ (f ⊗ g) == g ∘ snd.
  Proof. intros A B C D f g.
         unfold parallel.
         rewrite pair_snd.
         reflexivity.
  Qed.
  

  Lemma pair_f : forall {A B C D : U} (f : A ~~> B) (h : B ~~> C) (k : B ~~> D),
      ⟨h, k⟩ ∘ f == ⟨h ∘ f, k ∘ f⟩.
  Proof. intros A B C D f h k. apply proj_eq.
         - rewrite pair_fst, compose_assoc, pair_fst. reflexivity.
         - rewrite pair_snd, compose_assoc, pair_snd. reflexivity.
  Defined.

  Lemma diagonal_fst : forall {A : U}, fst ∘ diagonal (A:=A) == id.
  Proof. intros A. unfold diagonal. apply pair_fst.
  Defined.

  Lemma diagonal_snd : forall {A : U}, snd ∘ diagonal (A:=A) == id.
  Proof. intros A. unfold diagonal. apply pair_snd.
  Defined.

  Lemma fst_Epi : forall {A B}, (A ~~> B) -> Epi (fst (A:=A)(B:=B)).
  Proof. intros A B f.
         assert (fst (A:=A)(B:=B) ∘ (⟨id, f⟩) == id).
         { rewrite pair_fst. reflexivity. }
         unfold Epi. intros X g1 g2 K.
         rewrite <- (compose_id_right g1), <- (compose_id_right g2).
         rewrite <- H.
         rewrite !compose_assoc.
         rewrite K.
         reflexivity.
  Qed.
         
  Lemma pair_parallel_diagonal : forall {A B C : U} (f : A ~~> B) (g : A ~~> C),
      ⟨f, g⟩ == (f ⊗ g) ∘ diagonal.
  Proof. intros A B C f g. apply proj_eq.
         - rewrite compose_assoc, parallel_fst, pair_fst.
           rewrite <- compose_assoc, diagonal_fst, compose_id_right.
           reflexivity.
         - rewrite compose_assoc, parallel_snd, pair_snd.
           rewrite <- compose_assoc, diagonal_snd, compose_id_right.
           reflexivity.
  Defined.

  Lemma Mono_Proper : forall {A B}, Proper (eq ==> Logic.iff) (Mono  (A:=A) (B:=B)).
  Proof. intros. unfold Proper, respectful. intros.
         split.
         - intros Mx.
           unfold Mono; intros.
           rewrite <- !H in H0.
           apply Mx. assumption.
         - intros My.
           unfold Mono; intros.
           rewrite -> !H in H0.
           apply My. assumption.
  Qed.

  Lemma Mono_Compose : forall {A B C} {f : A ~~> B} {g : B ~~> C},
      Mono f -> Mono g -> Mono (g ∘ f).
  Proof.
    intros A B C f g Mf Mg.
    unfold Mono; intros X h1 h2 H.
    rewrite <- !compose_assoc in H.
    apply Mg in H. apply Mf in H. exact H.
  Qed.

  
  Lemma Iso_Mono : forall {A B} (x : A ≅ B), Mono (to x).
  Proof. intros A B x. destruct x as [f g fg gf].
         simpl. unfold Mono.
         intros X h k fhfk.
         rewrite <- (compose_id_left h), <- (compose_id_left k).
         rewrite <- !gf.
         rewrite <- !compose_assoc.
         apply compose_Proper; try reflexivity; try assumption.
  Qed.
  
  Lemma Iso_Epi : forall {A B} (x : A ≅ B), Epi (to x).
  Proof. intros A B x. destruct x as [f g fg gf].
         simpl. unfold Epi.
         intros X h k fhfk.
         rewrite <- (compose_id_right h), <- (compose_id_right k).
         rewrite <- !fg.
         rewrite -> !compose_assoc.
         apply compose_Proper; try reflexivity; try assumption.
  Qed.

  Lemma Iso_Refl {A} : A ≅ A.
  Proof.
  refine ( {| to := id ; from := id |});
  rewrite !compose_id_left; reflexivity.
  Defined.

  Definition Iso_Sym {A B} (i : A ≅ B) : B ≅ A :=
     {| to := from i
      ; from := to i
      ; to_from := from_to i
      ; from_to := to_from i
     |}.

  Lemma Iso_Trans {A B C} (ab : A ≅ B) (bc : B ≅ C) : A ≅ C.
  Proof.
  refine ({| to := to bc ∘ to ab
           ; from := from ab ∘ from bc |}).
  rewrite <- compose_assoc.
  rewrite (compose_assoc (from bc)).
  rewrite to_from. rewrite compose_id_left.
  apply to_from.
  rewrite <- compose_assoc.
  rewrite (compose_assoc (to ab)).
  rewrite from_to. rewrite compose_id_left.
  apply from_to.
  Defined.

  Lemma parallel_compose {A B C A' B' C'} 
   (f' : A ~~> B) (f : B ~~> C) (g' : A' ~~> B') (g : B' ~~> C') :
   f ⊗ g ∘ f' ⊗ g' == (f ∘ f') ⊗ (g ∘ g').
  Proof.
  unfold parallel. rewrite pair_f.
  apply pair_Proper; rewrite <- !compose_assoc;
    (apply compose_Proper; [ reflexivity |]).
  rewrite pair_fst. reflexivity.
  rewrite pair_snd. reflexivity.
  Qed.

  Lemma parallel_id A B
    : id (A := A) ⊗ id (A := B) == id.
  Proof.
  unfold parallel.  rewrite !compose_id_left.
  apply pair_id.
  Qed.

  Lemma Iso_Prod {A B A' B'} (a : A ≅ A') (b : B ≅ B')
    : A * B ≅ A' * B'.
  Proof.
  refine (
    {| to := to a ⊗ to b
     ; from := from a ⊗ from b
    |}
  ); rewrite parallel_compose.
  rewrite !to_from. apply parallel_id.
  rewrite !from_to. apply parallel_id.
  Defined.

Definition prod_assoc_left {U} `{CMC U} {A B C : U} 
  : A * (B * C) ~~> (A * B) * C := 
  ⟨id ⊗ fst, snd ∘ snd⟩.

Definition prod_assoc_right {U} `{CMC U} {A B C : U} 
  : (A * B) * C ~~> A * (B * C) := 
  ⟨fst ∘ fst, snd ⊗ id⟩.

  Lemma Iso_Prod_Assoc {A B C}
   : A * (B * C) ≅ (A * B) * C.
  Proof.
  refine (
   {| to := prod_assoc_left
    ; from := prod_assoc_right
   |}); unfold prod_assoc_left, prod_assoc_right; intros;
  rewrite pair_f;
  rewrite <- pair_id; apply pair_Proper.
  - rewrite parallel_pair.
    rewrite compose_id_left. unfold parallel.
    rewrite <- (compose_id_left (fst (A := A * B))) at 3.
    rewrite <- pair_id.
    rewrite pair_f. apply pair_Proper. reflexivity.
    rewrite pair_fst. reflexivity.
  - rewrite <- compose_assoc. rewrite pair_snd.
    rewrite parallel_snd. rewrite compose_id_left. reflexivity.
  - unfold parallel.
    rewrite <- compose_assoc.
    rewrite pair_fst. rewrite pair_fst. rewrite compose_id_left.
    reflexivity.
  - rewrite parallel_pair.
    rewrite <- (compose_id_left (snd (B := B * C))) at 2.
    rewrite <- pair_id.
    rewrite pair_f. apply pair_Proper. rewrite parallel_snd.
    reflexivity. rewrite compose_id_left. reflexivity.
  Defined.

  Lemma Iso_add_unit_left {A}
    : unit * A ≅ A.
  Proof.
  refine (
    {| to := snd 
     ; from := add_unit_left
    |}); unfold add_unit_left.
  - apply pair_snd.
  - rewrite pair_f.
    rewrite (unit_uniq _ fst). rewrite compose_id_left.
    apply pair_id.
  Defined.

  Lemma swap_sym : forall {A B}, swap (B:=B)(A:=A) ∘ swap == id.
  Proof.
    intros A B.
    unfold swap.
    rewrite !pair_f.
    rewrite pair_fst, pair_snd.
    apply pair_id.
  Qed.

  Lemma Iso_Prod_Symm : forall {A B}, A * B ≅ B * A.
  Proof. intros A B.
         unshelve eapply Build_Iso; try apply swap; try apply swap_sym.
  Defined.
         

Require Types.Setoid.

Definition Hom_Setoid A B :=
  {| Setoid.sty := A ~~> B
   ; Setoid.seq := eq
  |}.

  Lemma Hom_Setoid_Iso {A A' B B'}
    (a : A ≅ A') (b : B ≅ B')
    : Setoid.Iso (Hom_Setoid A B) (Hom_Setoid A' B').
  Proof.
  simple refine (Setoid.Build_Iso _ _ _ _ _ _ _ _); simpl.
  - exact (fun f => to b ∘ f ∘ from a).
  - exact (fun f => from b ∘ f ∘ to a).
  - unfold Proper, respectful. intros.
    rewrite H; reflexivity.
  - unfold Proper, respectful. intros.
    rewrite H; reflexivity.
  - simpl. intros. rewrite !compose_assoc.
    rewrite (to_from b). rewrite compose_id_left.
    rewrite <- compose_assoc. rewrite to_from.
    apply compose_id_right.
  - simpl. intros. rewrite !compose_assoc.
    rewrite from_to. rewrite compose_id_left.
    rewrite <- compose_assoc. rewrite from_to.
    apply compose_id_right.
  Defined.

  Lemma pair_parallel_id {Γ A B C} (f : Γ ~~> A)
        (g : Γ ~~> B) (h : B ~~> C)
    : ⟨ f, h ∘ g ⟩ == (id ⊗ h) ∘ ⟨ f , g ⟩.
  Proof.
    rewrite <- (compose_id_left f).
    rewrite parallel_pair.
    rewrite !compose_id_left. reflexivity.
  Qed.

End BasicProps.


End Category.